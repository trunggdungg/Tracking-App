import 'dart:async';

import '../../domain/device_command.dart';
import '../../domain/device_issue.dart';
import '../../domain/device_repository.dart';
import '../../domain/history_store.dart';
import '../../domain/telemetry_data.dart';
import '../blynk/blynk_api.dart';
import '../blynk/blynk_config.dart';
import '../blynk/blynk_parser.dart';

/// DeviceRepository chạy trên Blynk Cloud bằng polling HTTPS.
/// Mọi chi tiết "pin" nằm trong [BlynkConfig.pinMap]; UI không biết gì về Blynk.
class BlynkRepository implements DeviceRepository {
  BlynkRepository({
    required this.config,
    required HistoryStore store,
    BlynkApi? api,
  }) : _store = store,
       _api =
           api ??
           (config.hasToken
               ? BlynkApi(host: config.host, token: config.token!)
               : null);

  final BlynkConfig config;
  final HistoryStore _store;
  final BlynkApi? _api;

  final _telemetry = StreamController<TelemetryData>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final _issue = StreamController<DeviceIssue>.broadcast();

  Timer? _timer;
  bool _started = false;
  bool _paused = false;
  bool _fatal = false; // lỗi cấu hình/token: dừng hẳn cho tới khi tạo repo mới
  bool _polling = false;
  bool _disposed = false;
  int _failures = 0;
  bool _connected = false;
  DeviceIssue _currentIssue = DeviceIssue.none;

  /// Sau chừng này chu kỳ liên tiếp không có dữ liệu mới thì coi là ngắt kết nối.
  static const maxMissedCycles = 3;

  /// Chờ bao lâu trước chu kỳ kế tiếp. Lỗi liên tiếp thì giãn dần (gấp đôi mỗi
  /// lần, tối đa 60 giây) để không dồn dập gọi khi mất mạng.
  static Duration nextDelay(Duration base, int failures) {
    if (failures <= 0) return base;
    final factor = 1 << (failures > 6 ? 6 : failures);
    final d = base * factor;
    return d > const Duration(seconds: 60) ? const Duration(seconds: 60) : d;
  }

  // ---- DeviceRepository -------------------------------------------------

  @override
  Stream<TelemetryData> telemetryStream() {
    _start();
    return _telemetry.stream;
  }

  @override
  Stream<bool> connectionStream() async* {
    yield _connected;
    yield* _connection.stream;
  }

  @override
  Stream<DeviceIssue> issueStream() async* {
    yield _currentIssue;
    yield* _issue.stream;
  }

  @override
  void pause() {
    // App vào nền: dừng polling để đỡ tốn pin và mạng.
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void resume() {
    if (!_paused) return;
    _paused = false;
    if (_started && !_fatal && !_disposed) unawaited(_poll());
  }

  @override
  Future<bool> sendCommand(DeviceCommand cmd) async {
    final api = _api;
    final pins = config.pinMap;
    if (api == null || _fatal) return false;

    // Ánh xạ lệnh -> pin: chỉ nơi này biết lệnh nào ghi vào pin nào.
    final Map<int, String> values;
    switch (cmd) {
      case MotorEnableCommand(:final enable):
        final pin = pins.motorSwitch;
        if (pin == null) return false;
        values = {pin: enable ? '1' : '0'};
      case EmergencyStopCommand():
        final stop = pins.emergencyStop;
        if (stop == null) return false;
        values = {stop: '1'};
        final motor = pins.motorSwitch;
        if (motor != null) values[motor] = '0';
      case BuzzerMuteCommand(:final mute):
        final pin = pins.buzzerMute;
        if (pin == null) return false; // thiết bị không hỗ trợ tắt còi
        values = {pin: mute ? '1' : '0'};
    }

    try {
      await api.update(values);
      return true;
    } on BlynkException catch (e) {
      if (!_handleFatal(e) && e.kind == BlynkErrorKind.rateLimited) {
        _setIssue(DeviceIssue.quotaExceeded);
      }
      return false;
    }
  }

  @override
  Future<List<TelemetryData>> history(
    DateTime from,
    DateTime to, {
    int? maxPoints,
  }) => _store.telemetryBetween(from, to, maxPoints: maxPoints);

  @override
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _api?.close();
    await _telemetry.close();
    await _connection.close();
    await _issue.close();
  }

  // ---- Polling ----------------------------------------------------------

  void _start() {
    if (_started) return;
    _started = true;
    if (!config.hasToken || config.pinMap.missingRequired.isNotEmpty) {
      _fatal = true;
      _setIssue(DeviceIssue.notConfigured);
      return;
    }
    unawaited(_poll());
  }

  void _schedule() {
    if (_disposed || _paused || _fatal) return;
    _timer?.cancel();
    _timer = Timer(nextDelay(config.pollInterval, _failures), _poll);
  }

  Future<void> _poll() async {
    final api = _api;
    if (api == null || _polling || _disposed || _paused || _fatal) return;
    _polling = true;
    try {
      final pins = config.pinMap.readPins;
      // Đọc giá trị và hỏi thiết bị có online không trong cùng một chu kỳ.
      final results = await Future.wait<Object>([
        api.getRaw(pins),
        api.isHardwareConnected(),
      ]);
      if (_disposed) return;

      final online = results[1] as bool;
      if (!online) {
        // Blynk vẫn trả giá trị cũ khi thiết bị offline: không phát dữ liệu cũ.
        _failures = 0;
        _setConnected(false);
        return;
      }

      final values = parseGetResponse(results[0] as String, pins);
      final data = buildTelemetry(values, config.pinMap, DateTime.now());
      if (data == null) {
        _onMissed();
        return;
      }
      _failures = 0;
      _setIssue(DeviceIssue.none);
      _setConnected(true);
      if (!_telemetry.isClosed) _telemetry.add(data);
    } on BlynkException catch (e) {
      if (!_handleFatal(e)) {
        // Hết hạn mức: báo rõ nguyên nhân; vẫn thử lại (giãn dần tới 60 giây).
        if (e.kind == BlynkErrorKind.rateLimited) {
          _setIssue(DeviceIssue.quotaExceeded);
        }
        _onMissed();
      }
    } on BlynkParseException {
      _onMissed();
    } finally {
      _polling = false;
      _schedule();
    }
  }

  /// Chu kỳ này không có dữ liệu mới.
  void _onMissed() {
    _failures++;
    if (_failures >= maxMissedCycles) _setConnected(false);
  }

  /// Token sai / pin sai không tự hết: báo lỗi và dừng polling.
  bool _handleFatal(BlynkException e) {
    switch (e.kind) {
      case BlynkErrorKind.invalidToken:
        _fatal = true;
        _setIssue(DeviceIssue.invalidToken);
      case BlynkErrorKind.invalidPin:
        _fatal = true;
        _setIssue(DeviceIssue.invalidPins);
      default:
        return false;
    }
    _timer?.cancel();
    _setConnected(false);
    return true;
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connection.isClosed) _connection.add(value);
  }

  void _setIssue(DeviceIssue value) {
    if (_currentIssue == value) return;
    _currentIssue = value;
    if (!_issue.isClosed) _issue.add(value);
  }
}
