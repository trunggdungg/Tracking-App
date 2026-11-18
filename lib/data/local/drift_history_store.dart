import 'package:drift/drift.dart';

import '../../domain/alert_event.dart';
import '../../domain/history_store.dart';
import '../../domain/telemetry_data.dart';
import 'app_database.dart';

/// HistoryStore lưu trong SQLite bằng drift.
class DriftHistoryStore implements HistoryStore {
  DriftHistoryStore(this._db);

  final AppDatabase _db;

  static int _ms(DateTime t) => t.millisecondsSinceEpoch;

  @override
  Future<void> insertTelemetry(List<TelemetryData> rows) async {
    if (rows.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.telemetryRows, [
        for (final d in rows)
          TelemetryRowsCompanion.insert(
            ts: _ms(d.timestamp),
            rpm: d.rpm,
            temperature: d.temperature,
            vibration: Value(d.vibration),
            current: Value(d.current),
            health: Value(d.healthPercent),
            fault: Value(d.fault),
            level: d.warningLevel.index,
            buzzerOn: d.buzzerOn,
          ),
      ]);
    });
  }

  @override
  Future<List<TelemetryData>> telemetryBetween(
    DateTime from,
    DateTime to, {
    int? maxPoints,
  }) async {
    final f = _ms(from);
    final t = _ms(to);

    if (maxPoints != null) {
      final count =
          await (_db.selectOnly(_db.telemetryRows)
                ..addColumns([_db.telemetryRows.id.count()])
                ..where(_db.telemetryRows.ts.isBetweenValues(f, t)))
              .map((r) => r.read(_db.telemetryRows.id.count()) ?? 0)
              .getSingle();
      if (count > maxPoints) return _bucketed(f, t, maxPoints);
    }

    final query = _db.select(_db.telemetryRows)
      ..where((r) => r.ts.isBetweenValues(f, t))
      ..orderBy([(r) => OrderingTerm.asc(r.ts)]);
    return (await query.get()).map(_toDomain).toList();
  }

  /// Giảm mẫu ngay trong SQL: chia [f, t] thành [n] nhóm đều nhau theo thời gian,
  /// mỗi nhóm lấy trung bình (mức cảnh báo lấy MAX để không che mất sự kiện).
  /// Nhờ vậy 7 ngày dữ liệu (hàng trăm nghìn dòng) không phải nạp hết vào bộ nhớ.
  Future<List<TelemetryData>> _bucketed(int f, int t, int n) async {
    final rows = await _db
        .customSelect(
          'SELECT CAST(AVG(ts) AS INTEGER) AS ts, AVG(rpm) AS rpm, '
          'AVG(temperature) AS temperature, AVG(vibration) AS vibration, '
          'AVG(current) AS current, AVG(health) AS health, '
          'MAX(level) AS level, MAX(buzzer_on) AS buzzer_on '
          'FROM telemetry WHERE ts BETWEEN ? AND ? '
          'GROUP BY CAST((ts - ?) * ? / (? - ? + 1) AS INTEGER) '
          'ORDER BY ts',
          variables: [
            Variable.withInt(f),
            Variable.withInt(t),
            Variable.withInt(f),
            Variable.withInt(n),
            Variable.withInt(t),
            Variable.withInt(f),
          ],
          readsFrom: {_db.telemetryRows},
        )
        .get();

    return [
      for (final r in rows)
        TelemetryData(
          timestamp: DateTime.fromMillisecondsSinceEpoch(r.read<int>('ts')),
          rpm: r.read<double>('rpm'),
          temperature: r.read<double>('temperature'),
          vibration: r.readNullable<double>('vibration'),
          current: r.readNullable<double>('current'),
          healthPercent: r.readNullable<double>('health'),
          warningLevel: WarningLevel.values[r.read<int>('level')],
          buzzerOn: r.read<int>('buzzer_on') != 0,
        ),
    ];
  }

  TelemetryData _toDomain(TelemetryRow r) => TelemetryData(
    timestamp: DateTime.fromMillisecondsSinceEpoch(r.ts),
    rpm: r.rpm,
    temperature: r.temperature,
    vibration: r.vibration,
    current: r.current,
    healthPercent: r.health,
    fault: r.fault,
    warningLevel: WarningLevel.values[r.level],
    buzzerOn: r.buzzerOn,
  );

  @override
  Future<void> insertAlert(AlertEvent e) => _db
      .into(_db.alertRows)
      .insert(
        AlertRowsCompanion.insert(
          ts: _ms(e.timestamp),
          level: e.level.index,
          type: e.type.name,
          value: Value(e.value),
          message: Value(e.message),
        ),
      );

  @override
  Future<List<AlertEvent>> alertsBetween(DateTime from, DateTime to) async {
    final query = _db.select(_db.alertRows)
      ..where((r) => r.ts.isBetweenValues(_ms(from), _ms(to)))
      ..orderBy([(r) => OrderingTerm.desc(r.ts)]);
    return [
      for (final r in await query.get())
        AlertEvent(
          timestamp: DateTime.fromMillisecondsSinceEpoch(r.ts),
          level: WarningLevel.values[r.level],
          type: AlertType.values.firstWhere(
            (t) => t.name == r.type,
            orElse: () => AlertType.device,
          ),
          value: r.value,
          message: r.message,
        ),
    ];
  }

  @override
  Future<int> deleteBefore(DateTime cutoff) async {
    final c = _ms(cutoff);
    final a = await (_db.delete(
      _db.telemetryRows,
    )..where((r) => r.ts.isSmallerThanValue(c))).go();
    final b = await (_db.delete(
      _db.alertRows,
    )..where((r) => r.ts.isSmallerThanValue(c))).go();
    return a + b;
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.telemetryRows).go();
    await _db.delete(_db.alertRows).go();
  }

  @override
  Future<void> close() => _db.close();
}
