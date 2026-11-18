import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/data/local/app_database.dart';
import 'package:tracking_app/data/local/drift_history_store.dart';
import 'package:tracking_app/data/local/memory_history_store.dart';
import 'package:tracking_app/domain/alert_event.dart';
import 'package:tracking_app/domain/history_store.dart';
import 'package:tracking_app/domain/telemetry_data.dart';

final base = DateTime(2026, 1, 1, 12);

TelemetryData at(
  int seconds, {
  double rpm = 1400,
  double temp = 40,
  double? vibration,
  String? fault,
  WarningLevel level = WarningLevel.ok,
}) => TelemetryData(
  timestamp: base.add(Duration(seconds: seconds)),
  rpm: rpm,
  temperature: temp,
  vibration: vibration,
  fault: fault,
  warningLevel: level,
);

/// Cùng một bộ test chạy cho cả hai bản cài đặt để chúng hành xử giống nhau.
void storeContract(String name, HistoryStore Function() create) {
  group(name, () {
    late HistoryStore store;
    setUp(() => store = create());
    tearDown(() => store.close());

    test('ghi rồi đọc lại đủ trường, đúng thứ tự thời gian', () async {
      await store.insertTelemetry([
        at(10, vibration: 2.5, fault: 'Quá nhiệt', level: WarningLevel.danger),
        at(0),
        at(5, rpm: 1500),
      ]);
      final rows = await store.telemetryBetween(
        base,
        base.add(const Duration(minutes: 1)),
      );
      expect(rows.map((r) => r.timestamp.difference(base).inSeconds), [
        0,
        5,
        10,
      ]);
      expect(rows[1].rpm, 1500);
      expect(rows[0].vibration, isNull);
      expect(rows[2].vibration, 2.5);
      expect(rows[2].fault, 'Quá nhiệt');
      expect(rows[2].warningLevel, WarningLevel.danger);
    });

    test('chỉ trả về dữ liệu trong khoảng thời gian', () async {
      await store.insertTelemetry([at(0), at(100), at(200)]);
      final rows = await store.telemetryBetween(
        base.add(const Duration(seconds: 50)),
        base.add(const Duration(seconds: 150)),
      );
      expect(rows, hasLength(1));
    });

    test('giảm mẫu về tối đa maxPoints, giữ mức cảnh báo nặng nhất', () async {
      await store.insertTelemetry([
        for (var i = 0; i < 1000; i++)
          at(
            i,
            rpm: i.toDouble(),
            level: i == 421 ? WarningLevel.danger : WarningLevel.ok,
          ),
      ]);
      final out = await store.telemetryBetween(
        base,
        base.add(const Duration(seconds: 999)),
        maxPoints: 50,
      );
      expect(out.length, lessThanOrEqualTo(50));
      expect(out.length, greaterThan(40));
      expect(
        out.where((d) => d.warningLevel == WarningLevel.danger),
        hasLength(1),
      );
      for (var i = 1; i < out.length; i++) {
        expect(out[i].timestamp.isAfter(out[i - 1].timestamp), isTrue);
      }
    });

    test('ít điểm hơn maxPoints thì giữ nguyên dữ liệu thô', () async {
      await store.insertTelemetry([for (var i = 0; i < 10; i++) at(i)]);
      final out = await store.telemetryBetween(
        base,
        base.add(const Duration(minutes: 1)),
        maxPoints: 100,
      );
      expect(out, hasLength(10));
    });

    test('alerts: mới nhất trước và lọc theo khoảng', () async {
      AlertEvent ev(int s, AlertType t) => AlertEvent(
        timestamp: base.add(Duration(seconds: s)),
        level: WarningLevel.warn,
        type: t,
        value: 65,
      );
      await store.insertAlert(ev(0, AlertType.highTemp));
      await store.insertAlert(ev(60, AlertType.overheat));
      await store.insertAlert(ev(120, AlertType.vibration));
      final all = await store.alertsBetween(
        base,
        base.add(const Duration(hours: 1)),
      );
      expect(all.map((a) => a.type), [
        AlertType.vibration,
        AlertType.overheat,
        AlertType.highTemp,
      ]);
      expect(all.first.value, 65);
      final part = await store.alertsBetween(
        base.add(const Duration(seconds: 30)),
        base.add(const Duration(seconds: 90)),
      );
      expect(part.single.type, AlertType.overheat);
    });

    test('deleteBefore xóa cả mẫu đo lẫn cảnh báo cũ hơn mốc', () async {
      await store.insertTelemetry([at(0), at(100), at(200)]);
      await store.insertAlert(
        AlertEvent(
          timestamp: base,
          level: WarningLevel.warn,
          type: AlertType.highTemp,
        ),
      );
      final deleted = await store.deleteBefore(
        base.add(const Duration(seconds: 150)),
      );
      expect(deleted, 3); // 2 mẫu đo + 1 cảnh báo
      final left = await store.telemetryBetween(
        base,
        base.add(const Duration(hours: 1)),
      );
      expect(left, hasLength(1));
      expect(
        await store.alertsBetween(base, base.add(const Duration(hours: 1))),
        isEmpty,
      );
    });

    test('deleteAll xóa sạch', () async {
      await store.insertTelemetry([at(0), at(1)]);
      await store.deleteAll();
      expect(
        await store.telemetryBetween(base, base.add(const Duration(hours: 1))),
        isEmpty,
      );
    });
  });
}

void main() {
  storeContract(
    'DriftHistoryStore (SQLite)',
    () => DriftHistoryStore(AppDatabase(NativeDatabase.memory())),
  );
  storeContract('MemoryHistoryStore', MemoryHistoryStore.new);
}
