import 'dart:async';
import 'dart:math';

import '../../domain/device_command.dart';
import '../../domain/device_repository.dart';
import '../../domain/telemetry_data.dart';
import '../../domain/thresholds.dart';
import '../../domain/warning_evaluator.dart';

/// Bộ mô phỏng động cơ: mỗi lần gọi [next] cho ra một mẫu đo mới.
/// Tách khỏi repository để test được mà không cần timer.
class MockSimulator {
  MockSimulator({Random? random, this.thresholds = const Thresholds()})
    : _random = random ?? Random();

  final Random _random;
  final Thresholds thresholds;

  bool motorEnabled = true;
  bool buzzerMuted = false;

  int _tick = 0;
  double _rpm = 1400;
  double _temp = 38;
  bool _heating = true;
  double _peak = 70;

  double _noise(double amplitude) => (_random.nextDouble() * 2 - 1) * amplitude;

  TelemetryData next(DateTime now) {
    _tick++;

    // Tốc độ: dao động 1200-1600 khi chạy, giảm dần về 0 khi tắt.
    if (motorEnabled) {
      _rpm = (1400 + 150 * sin(_tick / 6) + _noise(40)).clamp(1200.0, 1600.0);
    } else {
      _rpm = _rpm < 5 ? 0 : _rpm * 0.7;
    }

    // Nhiệt độ: tăng dần tới đỉnh ngẫu nhiên (55-88 °C, thỉnh thoảng vượt
    // ngưỡng) rồi nguội xuống; khi tắt động cơ thì nguội về nhiệt độ phòng.
    if (motorEnabled && _heating) {
      _temp += 0.35 + _noise(0.1);
      if (_temp >= _peak) _heating = false;
    } else {
      _temp -= motorEnabled ? 0.8 : 0.5;
      final floor = motorEnabled ? 40.0 : 30.0;
      if (_temp <= floor) {
        _temp = floor;
        if (motorEnabled) {
          _heating = true;
          _peak = 55 + _random.nextDouble() * 33;
        }
      }
    }

    final vibration = 1.5 + (_temp - 40).clamp(0, 60) * 0.04 + _noise(0.2);
    final current = _rpm / 1500 * 4.5 + _noise(0.15);
    final health = (100 - (_temp - 40).clamp(0, 60) * 0.8).clamp(0.0, 100.0);

    var data = TelemetryData(
      timestamp: now,
      rpm: _rpm,
      temperature: _temp,
      vibration: max(0, vibration),
      current: max(0, current),
      healthPercent: health,
    );
    final level = WarningEvaluator.level(
      data,
      thresholds,
      motorRunning: motorEnabled,
    );
    if (level != WarningLevel.danger) buzzerMuted = false;
    data = TelemetryData(
      timestamp: now,
      rpm: _rpm,
      temperature: _temp,
      vibration: data.vibration,
      current: data.current,
      healthPercent: health,
      fault: level == WarningLevel.danger ? 'Quá nhiệt' : null,
      warningLevel: level,
      buzzerOn: level == WarningLevel.danger && !buzzerMuted,
    );
    return data;
  }
}

/// Repository giả để chạy UI khi chưa có thiết bị.
class MockRepository implements DeviceRepository {
  MockRepository({
    this.interval = const Duration(seconds: 1),
    this.commandDelay = const Duration(milliseconds: 400),
    this.failureRate = 0.1,
    this.simulateDropouts = true,
    Random? random,
    Thresholds thresholds = const Thresholds(),
  }) : _random = random ?? Random(),
       _sim = MockSimulator(random: random, thresholds: thresholds);

  final Duration interval;
  final Duration commandDelay;

  /// Xác suất lệnh thất bại (để thử luồng hoàn tác của công tắc).
  final double failureRate;

  /// Thỉnh thoảng giả lập mất kết nối vài giây.
  final bool simulateDropouts;

  final Random _random;
  final MockSimulator _sim;
  final _telemetry = StreamController<TelemetryData>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final _history = <TelemetryData>[];

  Timer? _timer;
  bool _connected = true;
  int _ticksUntilDropout = 30;
  int _dropoutTicksLeft = 0;

  static const _maxHistory = 20000;

  void _start() {
    _timer ??= Timer.periodic(interval, (_) => _tick());
    _tick();
  }

  void _tick() {
    if (_telemetry.isClosed) return;
    if (simulateDropouts) {
      if (_dropoutTicksLeft > 0) {
        _dropoutTicksLeft--;
        if (_dropoutTicksLeft == 0) _setConnected(true);
      } else if (--_ticksUntilDropout <= 0) {
        _dropoutTicksLeft = 4 + _random.nextInt(3);
        _ticksUntilDropout = 30 + _random.nextInt(30);
        _setConnected(false);
      }
    }
    if (!_connected) return; // mất kết nối: không có mẫu mới
    final data = _sim.next(DateTime.now());
    _history.add(data);
    if (_history.length > _maxHistory) {
      _history.removeRange(0, _history.length - _maxHistory);
    }
    _telemetry.add(data);
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connection.isClosed) _connection.add(value);
  }

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
  Future<bool> sendCommand(DeviceCommand cmd) async {
    await Future<void>.delayed(commandDelay);
    if (!_connected) return false;
    if (_random.nextDouble() < failureRate) return false;
    switch (cmd) {
      case MotorEnableCommand(:final enable):
        _sim.motorEnabled = enable;
      case EmergencyStopCommand():
        _sim.motorEnabled = false;
      case BuzzerMuteCommand(:final mute):
        _sim.buzzerMuted = mute;
    }
    return true;
  }

  @override
  Future<List<TelemetryData>> history(DateTime from, DateTime to) async => [
    for (final d in _history)
      if (!d.timestamp.isBefore(from) && !d.timestamp.isAfter(to)) d,
  ];

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _telemetry.close();
    await _connection.close();
  }
}
