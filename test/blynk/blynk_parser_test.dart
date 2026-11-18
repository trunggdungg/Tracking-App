import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/data/blynk/blynk_parser.dart';
import 'package:tracking_app/data/blynk/pin_map.dart';
import 'package:tracking_app/domain/telemetry_data.dart';

const pins = PinMap(rpm: 3, temperature: 4);
final now = DateTime(2026);

void main() {
  group('parseGetResponse', () {
    test('nhiều pin, giá trị là chuỗi', () {
      final v = parseGetResponse('{"v3":"1450","v4":"42.5"}', [3, 4]);
      expect(v, {3: '1450', 4: '42.5'});
    });

    test('nhiều pin, giá trị là số', () {
      final v = parseGetResponse('{"v3":1450,"v4":42.5}', [3, 4]);
      expect(asDouble(v[3]), 1450);
      expect(asDouble(v[4]), 42.5);
    });

    test('khóa viết hoa, khoảng trắng thừa, khóa lạ bị bỏ qua', () {
      final v = parseGetResponse(' {"V3":"1","foo":"x","v10":"7"} \n', [3, 10]);
      expect(v.keys, containsAll([3, 10]));
      expect(v.containsKey(0), isFalse);
      expect(v.length, 2);
    });

    test('một pin trả về chuỗi thô', () {
      expect(parseGetResponse('1450', [3]), {3: '1450'});
    });

    test('một pin trả về mảng thì lấy phần tử đầu', () {
      final v = parseGetResponse('["12.5","13"]', [3]);
      expect(asDouble(v[3]), 12.5);
    });

    test(
      'lỗi: rỗng, JSON hỏng, không phải object, thô nhưng hỏi nhiều pin',
      () {
        expect(
          () => parseGetResponse('', [3]),
          throwsA(isA<BlynkParseException>()),
        );
        expect(
          () => parseGetResponse('{"v3":', [3]),
          throwsA(isA<BlynkParseException>()),
        );
        expect(
          () => parseGetResponse('{"v3":1', [3, 4]),
          throwsA(isA<BlynkParseException>()),
        );
        expect(
          () => parseGetResponse('1450', [3, 4]),
          throwsA(isA<BlynkParseException>()),
        );
      },
    );
  });

  group('asDouble', () {
    test('các kiểu giá trị', () {
      expect(asDouble(5), 5);
      expect(asDouble(' 3.5 '), 3.5);
      expect(asDouble('3,5'), 3.5);
      expect(asDouble(true), 1);
      expect(asDouble(['7']), 7);
      expect(asDouble('abc'), isNull);
      expect(asDouble(null), isNull);
      expect(asDouble(<Object>[]), isNull);
    });
  });

  group('buildTelemetry', () {
    test('dựng mẫu từ giá trị pin', () {
      final d = buildTelemetry({3: '1450', 4: '42.5'}, pins, now)!;
      expect(d.rpm, 1450);
      expect(d.temperature, 42.5);
      expect(d.vibration, isNull);
      expect(d.fault, isNull);
      expect(d.motorOn, isNull);
      expect(d.timestamp, now);
    });

    test('thiếu hoặc không đọc được tốc độ/nhiệt độ -> null', () {
      expect(buildTelemetry({3: '1450'}, pins, now), isNull);
      expect(buildTelemetry({3: 'x', 4: '40'}, pins, now), isNull);
      expect(
        buildTelemetry({3: '1', 4: '2'}, const PinMap(), now),
        isNull,
        reason: 'pin tốc độ/nhiệt độ chưa cấu hình',
      );
    });

    test('các trường tùy chọn đọc đúng pin', () {
      const p = PinMap(
        rpm: 3,
        temperature: 4,
        vibration: 5,
        current: 6,
        health: 7,
        fault: 8,
        warningLamp: 9,
        buzzer: 10,
        motorSwitch: 0,
      );
      final d = buildTelemetry(
        {
          0: '1',
          3: '1450',
          4: '42',
          5: '2.5',
          6: '4.1',
          7: '88',
          8: 'Kẹt trục',
          9: '2',
          10: '1',
        },
        p,
        now,
      )!;
      expect(d.vibration, 2.5);
      expect(d.current, 4.1);
      expect(d.healthPercent, 88);
      expect(d.fault, 'Kẹt trục');
      expect(d.warningLevel, WarningLevel.danger);
      expect(d.buzzerOn, isTrue);
      expect(d.motorOn, isTrue);
    });

    test('fault "0" hoặc rỗng nghĩa là không lỗi; motorSwitch 0 là tắt', () {
      const p = PinMap(rpm: 3, temperature: 4, fault: 8, motorSwitch: 0);
      final d = buildTelemetry({0: '0', 3: '0', 4: '30', 8: '0'}, p, now)!;
      expect(d.fault, isNull);
      expect(d.motorOn, isFalse);
      expect(buildTelemetry({3: '1', 4: '2', 8: ''}, p, now)!.fault, isNull);
    });

    test('đèn cảnh báo: 0 ok, 1 warn, từ 2 danger', () {
      expect(warningLevelFromLamp(0), WarningLevel.ok);
      expect(warningLevelFromLamp(1), WarningLevel.warn);
      expect(warningLevelFromLamp(2), WarningLevel.danger);
      expect(warningLevelFromLamp(255), WarningLevel.danger);
    });
  });

  group('PinMap', () {
    test('readPins không trùng, bỏ null, sắp xếp', () {
      const p = PinMap(motorSwitch: 0, rpm: 3, temperature: 3, vibration: 1);
      expect(p.readPins, [0, 1, 3]);
    });

    test('missingRequired và so sánh bằng nhau', () {
      expect(const PinMap().missingRequired, ['rpm', 'temperature']);
      expect(const PinMap(rpm: 1, temperature: 2).missingRequired, isEmpty);
      expect(const PinMap(rpm: 1), const PinMap(rpm: 1));
      expect(const PinMap(rpm: 1) == const PinMap(rpm: 2), isFalse);
    });

    test('mặc định theo dashboard: V0, V1, V2', () {
      const p = PinMap();
      expect([p.motorSwitch, p.chartValue, p.emergencyStop], [0, 1, 2]);
    });
  });
}
