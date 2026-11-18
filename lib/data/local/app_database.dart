import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Bảng telemetry: mỗi lần đọc thiết bị thành công ghi một dòng.
@DataClassName('TelemetryRow')
@TableIndex(name: 'telemetry_ts', columns: {#ts})
class TelemetryRows extends Table {
  @override
  String get tableName => 'telemetry';

  IntColumn get id => integer().autoIncrement()();

  /// Thời điểm đo, epoch millisecond.
  IntColumn get ts => integer()();
  RealColumn get rpm => real()();
  RealColumn get temperature => real()();
  RealColumn get vibration => real().nullable()();
  RealColumn get current => real().nullable()();
  RealColumn get health => real().nullable()();
  TextColumn get fault => text().nullable()();

  /// WarningLevel.index (0 ok, 1 warn, 2 danger).
  IntColumn get level => integer()();
  BoolColumn get buzzerOn => boolean()();
}

/// Bảng alerts: một dòng mỗi lần mức cảnh báo tăng.
@DataClassName('AlertRow')
@TableIndex(name: 'alerts_ts', columns: {#ts})
class AlertRows extends Table {
  @override
  String get tableName => 'alerts';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get ts => integer()();
  IntColumn get level => integer()();

  /// AlertType.name
  TextColumn get type => text()();
  RealColumn get value => real().nullable()();
  TextColumn get message => text().nullable()();
}

@DriftDatabase(tables: [TelemetryRows, AlertRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tracking_app'));

  @override
  int get schemaVersion => 1;
}
