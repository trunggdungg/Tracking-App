import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/domain/telemetry_data.dart';
import 'package:tracking_app/domain/thresholds.dart';
import 'package:tracking_app/domain/warning_evaluator.dart';

TelemetryData sample({
  double rpm = 1400,
  double temp = 40,
  double? vibration,
  WarningLevel level = WarningLevel.ok,
}) => TelemetryData(
  timestamp: DateTime(2026),
  rpm: rpm,
  temperature: temp,
  vibration: vibration,
  warningLevel: level,
);

void main() {
  const t = Thresholds(); // rpm 800..1800, nhiệt độ 60/80, rung 7
  const eval = WarningEvaluator.level;

  group('speed', () {
    test('các trạng thái', () {
      expect(WarningEvaluator.speed(0, t), SpeedStatus.stopped);
      expect(WarningEvaluator.speed(500, t), SpeedStatus.low);
      expect(WarningEvaluator.speed(1400, t), SpeedStatus.stable);
      expect(WarningEvaluator.speed(1900, t), SpeedStatus.high);
    });

    test('biên: đúng ngưỡng vẫn là ổn định', () {
      expect(WarningEvaluator.speed(800, t), SpeedStatus.stable);
      expect(WarningEvaluator.speed(1800, t), SpeedStatus.stable);
    });
  });

  group('temperature', () {
    test('biên: đúng ngưỡng thì chuyển mức', () {
      expect(WarningEvaluator.temperature(59.9, t), TempStatus.normal);
      expect(WarningEvaluator.temperature(60, t), TempStatus.high);
      expect(WarningEvaluator.temperature(79.9, t), TempStatus.high);
      expect(WarningEvaluator.temperature(80, t), TempStatus.overheat);
    });
  });

  group('level', () {
    test('bình thường -> ok', () {
      expect(eval(sample(), t), WarningLevel.ok);
    });

    test('động cơ dừng không phải cảnh báo', () {
      expect(eval(sample(rpm: 0), t), WarningLevel.ok);
    });

    test('nhiệt độ cao hoặc tốc độ lệch -> warn', () {
      expect(eval(sample(temp: 65), t), WarningLevel.warn);
      expect(eval(sample(rpm: 500), t), WarningLevel.warn);
      expect(eval(sample(rpm: 1900), t), WarningLevel.warn);
    });

    test('quá nhiệt hoặc rung mạnh -> danger', () {
      expect(eval(sample(temp: 85), t), WarningLevel.danger);
      expect(eval(sample(vibration: 7.5), t), WarningLevel.danger);
      expect(eval(sample(vibration: 3), t), WarningLevel.ok);
    });

    test('lấy mức nặng nhất khi có nhiều điều kiện', () {
      expect(eval(sample(temp: 65, vibration: 8), t), WarningLevel.danger);
    });

    test('đổi ngưỡng thì kết quả đổi theo', () {
      final strict = t.copyWith(tempWarn: 30);
      expect(eval(sample(temp: 40), strict), WarningLevel.warn);
    });
  });

  group('apply', () {
    test('giữ mức nặng hơn giữa thiết bị báo và tự tính', () {
      final fromDevice = sample(level: WarningLevel.danger);
      expect(
        WarningEvaluator.apply(fromDevice, t).warningLevel,
        WarningLevel.danger,
      );
      expect(
        WarningEvaluator.apply(sample(temp: 65), t).warningLevel,
        WarningLevel.warn,
      );
    });
  });
}
