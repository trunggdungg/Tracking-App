import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/core/utils/downsample.dart';
import 'package:tracking_app/domain/telemetry_data.dart';

List<TelemetryData> series(int n, {WarningLevel Function(int)? level}) => [
  for (var i = 0; i < n; i++)
    TelemetryData(
      timestamp: DateTime(2026).add(Duration(seconds: i)),
      rpm: i.toDouble(),
      temperature: 50,
      warningLevel: level?.call(i) ?? WarningLevel.ok,
    ),
];

void main() {
  test('ít điểm hơn giới hạn: giữ nguyên', () {
    final d = series(10);
    expect(downsample(d, 100), hasLength(10));
  });

  test('giảm đúng về maxPoints và giữ thứ tự thời gian', () {
    final out = downsample(series(1000), 100);
    expect(out, hasLength(100));
    for (var i = 1; i < out.length; i++) {
      expect(out[i].timestamp.isAfter(out[i - 1].timestamp), isTrue);
    }
  });

  test('lấy trung bình theo nhóm', () {
    final out = downsample(series(4), 2); // nhóm [0,1] và [2,3]
    expect(out[0].rpm, 0.5);
    expect(out[1].rpm, 2.5);
  });

  test('giữ mức cảnh báo nặng nhất trong nhóm', () {
    final out = downsample(
      series(
        100,
        level: (i) => i == 37 ? WarningLevel.danger : WarningLevel.ok,
      ),
      10,
    );
    expect(
      out.where((d) => d.warningLevel == WarningLevel.danger),
      hasLength(1),
    );
  });

  test('danh sách rỗng và maxPoints không hợp lệ', () {
    expect(downsample(const [], 10), isEmpty);
    expect(() => downsample(series(5), 0), throwsArgumentError);
  });

  test('trường tùy chọn null thì vẫn null', () {
    expect(downsample(series(100), 10).first.vibration, isNull);
  });
}
