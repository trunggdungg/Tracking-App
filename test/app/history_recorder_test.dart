import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/app/history_recorder.dart';
import 'package:tracking_app/data/local/memory_history_store.dart';
import 'package:tracking_app/domain/telemetry_data.dart';
import 'package:tracking_app/domain/thresholds.dart';
import 'package:tracking_app/domain/warning_evaluator.dart';

TelemetryData sample(int s, double temp) => WarningEvaluator.apply(
  TelemetryData(
    timestamp: DateTime(2026).add(Duration(seconds: s)),
    rpm: 1400,
    temperature: temp,
  ),
  const Thresholds(),
);

void main() {
  const t = Thresholds();

  test('gom mẫu và ghi theo lô khi flush', () async {
    final store = MemoryHistoryStore();
    final rec = HistoryRecorder(store, maxBuffer: 1000);
    for (var i = 0; i < 5; i++) {
      final d = sample(i, 40);
      rec.onSample(d, rec.detector.onSample(d, t));
    }
    final range = [DateTime(2025), DateTime(2027)];
    expect(
      await store.telemetryBetween(range[0], range[1]),
      isEmpty,
      reason: 'chưa flush thì chưa ghi',
    );
    await rec.flush();
    expect(await store.telemetryBetween(range[0], range[1]), hasLength(5));
  });

  test('tự flush khi buffer đầy', () async {
    final store = MemoryHistoryStore();
    final rec = HistoryRecorder(store, maxBuffer: 3);
    for (var i = 0; i < 3; i++) {
      final d = sample(i, 40);
      rec.onSample(d, rec.detector.onSample(d, t));
    }
    await Future<void>.delayed(Duration.zero);
    expect(
      await store.telemetryBetween(DateTime(2025), DateTime(2027)),
      hasLength(3),
    );
  });

  test(
    'chỉ ghi 1 cảnh báo cho cả đợt vượt ngưỡng, ghi lại ở đợt sau',
    () async {
      final store = MemoryHistoryStore();
      final rec = HistoryRecorder(store, maxBuffer: 1000);
      final temps = [40.0, 65, 66, 67, 68, 40, 41, 70, 71];
      for (var i = 0; i < temps.length; i++) {
        final d = sample(i, temps[i].toDouble());
        rec.onSample(d, rec.detector.onSample(d, t));
      }
      await Future<void>.delayed(Duration.zero);
      final alerts = await store.alertsBetween(DateTime(2025), DateTime(2027));
      expect(alerts, hasLength(2));
    },
  );
}
