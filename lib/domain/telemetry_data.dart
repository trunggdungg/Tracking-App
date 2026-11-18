/// Mức cảnh báo chung cho toàn app (xanh / vàng / đỏ).
enum WarningLevel {
  ok,
  warn,
  danger;

  /// Trả về mức nặng hơn trong hai mức.
  WarningLevel worst(WarningLevel other) => index >= other.index ? this : other;
}

/// Một mẫu đo từ thiết bị. Các trường có dấu `?` là tùy chọn:
/// UI tự ẩn nếu null (thiết bị chưa gửi / chưa cấu hình pin).
class TelemetryData {
  const TelemetryData({
    required this.timestamp,
    required this.rpm,
    required this.temperature,
    this.vibration,
    this.current,
    this.healthPercent,
    this.fault,
    this.warningLevel = WarningLevel.ok,
    this.buzzerOn = false,
    this.motorOn,
  });

  final DateTime timestamp;

  /// Tốc độ quay, vòng/phút.
  final double rpm;

  /// Nhiệt độ động cơ, °C.
  final double temperature;

  /// Rung, mm/s.
  final double? vibration;

  /// Dòng điện, A.
  final double? current;

  /// Chỉ số sức khỏe, 0-100.
  final double? healthPercent;

  /// Mô tả lỗi do thiết bị báo (null = không lỗi).
  final String? fault;

  final WarningLevel warningLevel;
  final bool buzzerOn;

  /// Trạng thái bật/tắt động cơ do thiết bị báo (null = thiết bị không báo).
  final bool? motorOn;

  TelemetryData copyWith({WarningLevel? warningLevel, bool? buzzerOn}) =>
      TelemetryData(
        timestamp: timestamp,
        rpm: rpm,
        temperature: temperature,
        vibration: vibration,
        current: current,
        healthPercent: healthPercent,
        fault: fault,
        warningLevel: warningLevel ?? this.warningLevel,
        buzzerOn: buzzerOn ?? this.buzzerOn,
        motorOn: motorOn,
      );

  @override
  String toString() =>
      'TelemetryData($timestamp rpm=$rpm temp=$temperature level=$warningLevel)';
}
