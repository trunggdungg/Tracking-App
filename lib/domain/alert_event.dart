import 'telemetry_data.dart';
import 'thresholds.dart';
import 'warning_evaluator.dart';

/// Nguyên nhân của một sự kiện cảnh báo.
enum AlertType {
  overheat,
  vibration,
  highTemp,
  lowSpeed,
  highSpeed,
  fault,
  device,
}

/// Một dòng trong bảng alerts.
class AlertEvent {
  const AlertEvent({
    required this.timestamp,
    required this.level,
    required this.type,
    this.value,
    this.message,
  });

  final DateTime timestamp;
  final WarningLevel level;
  final AlertType type;

  /// Giá trị đo lúc xảy ra (°C, vòng/phút, mm/s...). Null nếu không có.
  final double? value;

  /// Mô tả thêm (ví dụ chuỗi lỗi do thiết bị báo).
  final String? message;
}

/// Phát hiện lúc "chuyển trạng thái" để ghi alerts, tránh ghi lặp mỗi mẫu.
///
/// Chỉ ghi khi mức cảnh báo TĂNG (ok -> warn, ok -> danger, warn -> danger).
/// Hạ mức hoặc về ok thì không ghi; lần vượt ngưỡng sau sẽ ghi lại.
class AlertDetector {
  WarningLevel _previous = WarningLevel.ok;

  /// [d] phải là mẫu đã tính warningLevel (xem `WarningEvaluator.apply`).
  AlertEvent? onSample(
    TelemetryData d,
    Thresholds t, {
    bool motorRunning = true,
  }) {
    final level = d.warningLevel;
    final escalated = level.index > _previous.index;
    _previous = level;
    if (!escalated) return null;
    return _describe(d, t, level, motorRunning);
  }

  /// Chọn nguyên nhân nặng nhất: quá nhiệt / rung > nhiệt cao > tốc độ > lỗi > đèn thiết bị.
  AlertEvent _describe(
    TelemetryData d,
    Thresholds t,
    WarningLevel level,
    bool motorRunning,
  ) {
    AlertEvent e(AlertType type, {double? value, String? message}) =>
        AlertEvent(
          timestamp: d.timestamp,
          level: level,
          type: type,
          value: value,
          message: message,
        );

    final temp = WarningEvaluator.temperature(d.temperature, t);
    final speed = WarningEvaluator.speed(d.rpm, t, motorRunning: motorRunning);
    final vib = d.vibration;

    if (temp == TempStatus.overheat) {
      return e(AlertType.overheat, value: d.temperature);
    }
    if (vib != null && vib >= t.vibrationDanger) {
      return e(AlertType.vibration, value: vib);
    }
    if (temp == TempStatus.high) {
      return e(AlertType.highTemp, value: d.temperature);
    }
    if (speed == SpeedStatus.low) return e(AlertType.lowSpeed, value: d.rpm);
    if (speed == SpeedStatus.high) return e(AlertType.highSpeed, value: d.rpm);
    if (d.fault != null) return e(AlertType.fault, message: d.fault);
    return e(AlertType.device); // chỉ đèn cảnh báo của thiết bị bật
  }
}
