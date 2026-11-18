import '../../domain/telemetry_data.dart';
import '../../domain/warning_evaluator.dart';

extension SpeedStatusLabel on SpeedStatus {
  String get label => switch (this) {
    SpeedStatus.stopped => 'Động cơ đã dừng',
    SpeedStatus.low => 'Tốc độ thấp',
    SpeedStatus.stable => 'Tốc độ ổn định',
    SpeedStatus.high => 'Tốc độ quá cao',
  };
}

extension TempStatusLabel on TempStatus {
  String get label => switch (this) {
    TempStatus.normal => 'Nhiệt độ bình thường',
    TempStatus.high => 'Nhiệt độ cao',
    TempStatus.overheat => 'Quá nhiệt',
  };
}

extension WarningLevelLabel on WarningLevel {
  String get label => switch (this) {
    WarningLevel.ok => 'an toàn',
    WarningLevel.warn => 'chú ý',
    WarningLevel.danger => 'nguy hiểm',
  };
}
