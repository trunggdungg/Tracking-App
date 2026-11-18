import '../../core/utils/downsample.dart';
import '../../domain/alert_event.dart';
import '../../domain/history_store.dart';
import '../../domain/telemetry_data.dart';

/// HistoryStore trong bộ nhớ: dùng cho test và khi không cần lưu bền.
class MemoryHistoryStore implements HistoryStore {
  final _telemetry = <TelemetryData>[];
  final _alerts = <AlertEvent>[];

  @override
  Future<void> insertTelemetry(List<TelemetryData> rows) async {
    _telemetry.addAll(rows);
    _telemetry.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<List<TelemetryData>> telemetryBetween(
    DateTime from,
    DateTime to, {
    int? maxPoints,
  }) async {
    final rows = [
      for (final d in _telemetry)
        if (!d.timestamp.isBefore(from) && !d.timestamp.isAfter(to)) d,
    ];
    return maxPoints == null ? rows : downsample(rows, maxPoints);
  }

  @override
  Future<void> insertAlert(AlertEvent event) async => _alerts.add(event);

  @override
  Future<List<AlertEvent>> alertsBetween(DateTime from, DateTime to) async => [
    for (final a in _alerts)
      if (!a.timestamp.isBefore(from) && !a.timestamp.isAfter(to)) a,
  ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  @override
  Future<int> deleteBefore(DateTime cutoff) async {
    final before = _telemetry.length + _alerts.length;
    _telemetry.removeWhere((d) => d.timestamp.isBefore(cutoff));
    _alerts.removeWhere((a) => a.timestamp.isBefore(cutoff));
    return before - _telemetry.length - _alerts.length;
  }

  @override
  Future<void> deleteAll() async {
    _telemetry.clear();
    _alerts.clear();
  }

  @override
  Future<void> close() async {}
}
