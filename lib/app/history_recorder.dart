import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/alert_event.dart';
import '../domain/history_store.dart';
import '../domain/telemetry_data.dart';
import 'providers.dart';

/// Ghi mỗi mẫu đo vào lịch sử và ghi cảnh báo khi đổi trạng thái.
///
/// Đặt ở tầng app (không nằm trong từng repository) để dùng chung cho Mock,
/// Blynk... và lưu đúng mức cảnh báo đã tính theo ngưỡng của app.
/// Mẫu được gom lại và ghi theo lô để đỡ tốn I/O (mỗi vài giây một lần).
class HistoryRecorder {
  HistoryRecorder(
    this._store, {
    this.flushInterval = const Duration(seconds: 5),
    this.maxBuffer = 50,
  });

  final HistoryStore _store;
  final Duration flushInterval;
  final int maxBuffer;

  final _buffer = <TelemetryData>[];
  final _detector = AlertDetector();
  Timer? _timer;

  void start() => _timer ??= Timer.periodic(flushInterval, (_) => flush());

  /// Gọi với mỗi mẫu thành công (đã tính warningLevel).
  void onSample(TelemetryData d, AlertEvent? alert) {
    _buffer.add(d);
    // Cảnh báo ghi ngay để không mất khi app bị tắt đột ngột.
    if (alert != null) unawaited(_store.insertAlert(alert));
    if (_buffer.length >= maxBuffer) unawaited(flush());
  }

  AlertDetector get detector => _detector;

  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<TelemetryData>.of(_buffer);
    _buffer.clear();
    try {
      await _store.insertTelemetry(batch);
    } catch (_) {
      // Ghi lỗi thì bỏ lô này, không làm app crash (không log dữ liệu nhạy cảm).
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(flush());
  }
}

/// Số ngày giữ lịch sử. (Bước 3: lưu shared_preferences + chỉnh trong Cài đặt.)
class RetentionDaysNotifier extends Notifier<int> {
  @override
  int build() => 30;

  void set(int days) => state = days;
}

final retentionDaysProvider = NotifierProvider<RetentionDaysNotifier, int>(
  RetentionDaysNotifier.new,
);

/// Chạy ngầm suốt vòng đời app: ghi lịch sử + ghi cảnh báo + tự dọn dữ liệu cũ.
/// Được kích hoạt một lần từ AppShell.
final historyRecorderProvider = Provider<HistoryRecorder>((ref) {
  final store = ref.watch(historyStoreProvider);
  final recorder = HistoryRecorder(store)..start();

  ref.listen(telemetryProvider, (_, next) {
    final d = next.value;
    if (d == null) return;
    final alert = recorder.detector.onSample(
      d,
      ref.read(thresholdsProvider),
      motorRunning: ref.read(motorControllerProvider).enabled,
    );
    recorder.onSample(d, alert);
  });

  // Tự dọn dữ liệu cũ hơn N ngày: một lần lúc khởi động rồi mỗi giờ.
  Future<void> purge() async {
    final days = ref.read(retentionDaysProvider);
    try {
      await store.deleteBefore(DateTime.now().subtract(Duration(days: days)));
    } catch (_) {}
  }

  unawaited(purge());
  final purgeTimer = Timer.periodic(const Duration(hours: 1), (_) => purge());

  ref.onDispose(() {
    purgeTimer.cancel();
    recorder.dispose();
  });
  return recorder;
});
