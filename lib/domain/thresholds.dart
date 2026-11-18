/// Ngưỡng cảnh báo cấu hình được (chỉnh trong màn hình Cài đặt).
class Thresholds {
  const Thresholds({
    this.rpmLow = 800,
    this.rpmHigh = 1800,
    this.rpmMax = 2000,
    this.tempWarn = 60,
    this.tempDanger = 80,
    this.tempMax = 100,
    this.vibrationDanger = 7.0,
  });

  /// Dưới ngưỡng này (và > 0) là "tốc độ thấp".
  final double rpmLow;

  /// Trên ngưỡng này là "tốc độ quá cao".
  final double rpmHigh;

  /// Giá trị tối đa của thang gauge tốc độ.
  final double rpmMax;

  final double tempWarn;
  final double tempDanger;

  /// Giá trị tối đa của thang gauge nhiệt độ.
  final double tempMax;

  /// Rung (mm/s) từ ngưỡng này trở lên là nguy hiểm.
  final double vibrationDanger;

  Thresholds copyWith({
    double? rpmLow,
    double? rpmHigh,
    double? rpmMax,
    double? tempWarn,
    double? tempDanger,
    double? tempMax,
    double? vibrationDanger,
  }) => Thresholds(
    rpmLow: rpmLow ?? this.rpmLow,
    rpmHigh: rpmHigh ?? this.rpmHigh,
    rpmMax: rpmMax ?? this.rpmMax,
    tempWarn: tempWarn ?? this.tempWarn,
    tempDanger: tempDanger ?? this.tempDanger,
    tempMax: tempMax ?? this.tempMax,
    vibrationDanger: vibrationDanger ?? this.vibrationDanger,
  );

  @override
  bool operator ==(Object other) =>
      other is Thresholds &&
      other.rpmLow == rpmLow &&
      other.rpmHigh == rpmHigh &&
      other.rpmMax == rpmMax &&
      other.tempWarn == tempWarn &&
      other.tempDanger == tempDanger &&
      other.tempMax == tempMax &&
      other.vibrationDanger == vibrationDanger;

  @override
  int get hashCode => Object.hash(
    rpmLow,
    rpmHigh,
    rpmMax,
    tempWarn,
    tempDanger,
    tempMax,
    vibrationDanger,
  );
}
