import '../../domain/alert_event.dart';

extension AlertTypeLabel on AlertType {
  String get label => switch (this) {
    AlertType.overheat => 'Quá nhiệt',
    AlertType.vibration => 'Rung mạnh',
    AlertType.highTemp => 'Nhiệt độ cao',
    AlertType.lowSpeed => 'Tốc độ thấp',
    AlertType.highSpeed => 'Tốc độ quá cao',
    AlertType.fault => 'Lỗi thiết bị',
    AlertType.device => 'Đèn cảnh báo thiết bị',
  };

  String get unit => switch (this) {
    AlertType.overheat || AlertType.highTemp => '°C',
    AlertType.vibration => 'mm/s',
    AlertType.lowSpeed || AlertType.highSpeed => 'vòng/phút',
    AlertType.fault || AlertType.device => '',
  };
}

/// "65.2 °C", "1900 vòng/phút" hoặc chuỗi lỗi; rỗng nếu không có giá trị.
String alertValueText(AlertEvent e) {
  final v = e.value;
  if (v == null) return e.message ?? '';
  final num = e.type == AlertType.lowSpeed || e.type == AlertType.highSpeed
      ? v.round().toString()
      : v.toStringAsFixed(1);
  return '$num ${e.type.unit}'.trim();
}
