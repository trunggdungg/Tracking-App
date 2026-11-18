import 'telemetry_data.dart';
import 'thresholds.dart';

enum SpeedStatus {
  stopped,
  low,
  stable,
  high;

  WarningLevel get level => switch (this) {
    SpeedStatus.stopped || SpeedStatus.stable => WarningLevel.ok,
    SpeedStatus.low || SpeedStatus.high => WarningLevel.warn,
  };
}

enum TempStatus {
  normal,
  high,
  overheat;

  WarningLevel get level => switch (this) {
    TempStatus.normal => WarningLevel.ok,
    TempStatus.high => WarningLevel.warn,
    TempStatus.overheat => WarningLevel.danger,
  };
}

/// Toàn bộ logic cảnh báo nằm ở đây (hàm thuần, không phụ thuộc UI).
class WarningEvaluator {
  const WarningEvaluator._();

  static SpeedStatus speed(double rpm, Thresholds t) {
    if (rpm <= 0) return SpeedStatus.stopped;
    if (rpm < t.rpmLow) return SpeedStatus.low;
    if (rpm > t.rpmHigh) return SpeedStatus.high;
    return SpeedStatus.stable;
  }

  static TempStatus temperature(double celsius, Thresholds t) {
    if (celsius >= t.tempDanger) return TempStatus.overheat;
    if (celsius >= t.tempWarn) return TempStatus.high;
    return TempStatus.normal;
  }

  /// Mức cảnh báo tính từ giá trị đo: quá nhiệt hoặc rung mạnh = đỏ;
  /// nhiệt độ cao hoặc tốc độ lệch ngưỡng = vàng.
  static WarningLevel level(TelemetryData d, Thresholds t) {
    var result = WarningLevel.ok;
    result = result.worst(speed(d.rpm, t).level);
    result = result.worst(temperature(d.temperature, t).level);
    final v = d.vibration;
    if (v != null && v >= t.vibrationDanger) result = WarningLevel.danger;
    return result;
  }

  /// Gộp mức do thiết bị báo (đèn cảnh báo) với mức tự tính: lấy mức nặng hơn.
  static TelemetryData apply(TelemetryData d, Thresholds t) =>
      d.copyWith(warningLevel: d.warningLevel.worst(level(d, t)));
}
