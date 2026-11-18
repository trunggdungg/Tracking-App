import '../../domain/telemetry_data.dart';

/// Giảm mẫu danh sách đã sắp xếp theo thời gian xuống tối đa [maxPoints] điểm:
/// chia thành các nhóm đều nhau, mỗi nhóm lấy trung bình các giá trị số.
/// Mức cảnh báo lấy mức nặng nhất trong nhóm để không che mất sự kiện.
List<TelemetryData> downsample(List<TelemetryData> data, int maxPoints) {
  if (maxPoints < 1) throw ArgumentError.value(maxPoints, 'maxPoints');
  final n = data.length;
  if (n <= maxPoints) return List.of(data);

  final result = <TelemetryData>[];
  for (var i = 0; i < maxPoints; i++) {
    final start = i * n ~/ maxPoints;
    final end = (i + 1) * n ~/ maxPoints;
    result.add(_merge(data.sublist(start, end)));
  }
  return result;
}

double? _avg(Iterable<double?> values) {
  final v = values.whereType<double>().toList();
  if (v.isEmpty) return null;
  return v.reduce((a, b) => a + b) / v.length;
}

TelemetryData _merge(List<TelemetryData> g) {
  var level = WarningLevel.ok;
  for (final d in g) {
    level = level.worst(d.warningLevel);
  }
  return TelemetryData(
    timestamp: g[g.length ~/ 2].timestamp,
    rpm: _avg(g.map((d) => d.rpm))!,
    temperature: _avg(g.map((d) => d.temperature))!,
    vibration: _avg(g.map((d) => d.vibration)),
    current: _avg(g.map((d) => d.current)),
    healthPercent: _avg(g.map((d) => d.healthPercent)),
    fault: g.reversed
        .map((d) => d.fault)
        .firstWhere((f) => f != null, orElse: () => null),
    warningLevel: level,
    buzzerOn: g.any((d) => d.buzzerOn),
  );
}
