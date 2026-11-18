import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/domain/alert_event.dart';
import 'package:tracking_app/domain/telemetry_data.dart';
import 'package:tracking_app/domain/thresholds.dart';
import 'package:tracking_app/domain/warning_evaluator.dart';

const t = Thresholds();

/// Tạo mẫu đã tính mức cảnh báo, giống luồng thật trong telemetryProvider.
TelemetryData s({
  double rpm = 1400,
  double temp = 40,
  double? vibration,
  String? fault,
  bool motorRunning = true,
  WarningLevel device = WarningLevel.ok,
}) => WarningEvaluator.apply(
  TelemetryData(
    timestamp: DateTime(2026),
    rpm: rpm,
    temperature: temp,
    vibration: vibration,
    fault: fault,
    warningLevel: device,
  ),
  t,
  motorRunning: motorRunning,
);

void main() {
  test('ok -> ok không ghi gì', () {
    final d = AlertDetector();
    expect(d.onSample(s(), t), isNull);
    expect(d.onSample(s(), t), isNull);
  });

  test('ok -> warn ghi 1 dòng, các mẫu warn tiếp theo không ghi lặp', () {
    final d = AlertDetector();
    final e = d.onSample(s(temp: 65), t);
    expect(e, isNotNull);
    expect(e!.type, AlertType.highTemp);
    expect(e.level, WarningLevel.warn);
    expect(e.value, 65);
    for (var i = 0; i < 10; i++) {
      expect(d.onSample(s(temp: 66.0 + i), t), isNull);
    }
  });

  test('warn -> danger ghi thêm một dòng (mức tăng)', () {
    final d = AlertDetector();
    d.onSample(s(temp: 65), t);
    final e = d.onSample(s(temp: 85), t);
    expect(e!.type, AlertType.overheat);
    expect(e.level, WarningLevel.danger);
  });

  test('danger -> warn không ghi; về ok rồi vượt lại thì ghi lại', () {
    final d = AlertDetector();
    d.onSample(s(temp: 85), t);
    expect(d.onSample(s(temp: 70), t), isNull);
    expect(d.onSample(s(temp: 40), t), isNull);
    expect(d.onSample(s(temp: 65), t), isNotNull);
  });

  test('chọn đúng nguyên nhân', () {
    expect(AlertDetector().onSample(s(rpm: 500), t)!.type, AlertType.lowSpeed);
    expect(
      AlertDetector().onSample(s(rpm: 1900), t)!.type,
      AlertType.highSpeed,
    );
    expect(
      AlertDetector().onSample(s(vibration: 8), t)!.type,
      AlertType.vibration,
    );
    expect(
      AlertDetector()
          .onSample(s(fault: 'Kẹt', device: WarningLevel.warn), t)!
          .type,
      AlertType.fault,
    );
    expect(
      AlertDetector().onSample(s(device: WarningLevel.danger), t)!.type,
      AlertType.device,
    );
  });

  test('quá nhiệt ưu tiên hơn tốc độ thấp khi cả hai cùng xảy ra', () {
    final e = AlertDetector().onSample(s(rpm: 500, temp: 90), t)!;
    expect(e.type, AlertType.overheat);
  });

  test('động cơ tắt chủ động: rpm thấp không tạo cảnh báo', () {
    final d = AlertDetector();
    expect(
      d.onSample(s(rpm: 90, motorRunning: false), t, motorRunning: false),
      isNull,
    );
  });
}
