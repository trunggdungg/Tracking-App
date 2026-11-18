import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/data/blynk/blynk_api.dart';
import 'package:tracking_app/data/blynk/blynk_config.dart';
import 'package:tracking_app/data/blynk/pin_map.dart';

import '../support/fake_adapter.dart';

BlynkApi makeApi(
  FakeAdapter a, {
  String host = 'blynk.cloud',
  String token = 'TOK',
}) => BlynkApi(host: host, token: token, dio: fakeDio(a));

Future<BlynkErrorKind> errorOf(Future<Object?> f) async {
  try {
    await f;
  } on BlynkException catch (e) {
    return e.kind;
  }
  fail('đáng lẽ phải ném BlynkException');
}

void main() {
  group('URL', () {
    test('get: token + pin không giá trị (&v3&v4)', () async {
      final a = FakeAdapter((_) => const FakeReply(200, '{}'));
      await makeApi(a).getRaw([3, 4]);
      final u = a.requests.single;
      expect(u.scheme, 'https');
      expect(u.host, 'blynk.cloud');
      expect(u.path, '/external/api/get');
      expect(u.query, 'token=TOK&v3&v4');
    });

    test('update: nhiều pin trong một lệnh', () async {
      final a = FakeAdapter((_) => const FakeReply(200, ''));
      await makeApi(a).update({2: '1', 0: '0'});
      expect(a.requests.single.path, '/external/api/update');
      expect(a.requests.single.query, 'token=TOK&v2=1&v0=0');
    });

    test('isHardwareConnected', () async {
      final a = FakeAdapter((_) => const FakeReply(200, 'true'));
      await makeApi(a).isHardwareConnected();
      expect(a.requests.single.path, '/external/api/isHardwareConnected');
    });

    test('host theo vùng, chấp nhận dán cả https:// và dấu / cuối', () async {
      final a = FakeAdapter((_) => const FakeReply(200, '1'));
      await makeApi(a, host: ' https://sgp1.blynk.cloud/ ').getRaw([1]);
      expect(a.requests.single.host, 'sgp1.blynk.cloud');
      expect(normalizeHost(''), kDefaultBlynkHost);
    });

    test('token có ký tự đặc biệt được mã hóa', () async {
      final a = FakeAdapter((_) => const FakeReply(200, '1'));
      await makeApi(a, token: 'a b&c').getRaw([1]);
      expect(a.requests.single.query, startsWith('token=a+b%26c'));
    });
  });

  group('isHardwareConnected', () {
    test('true / false', () async {
      expect(
        await makeApi(
          FakeAdapter((_) => const FakeReply(200, 'true')),
        ).isHardwareConnected(),
        isTrue,
      );
      expect(
        await makeApi(
          FakeAdapter((_) => const FakeReply(200, 'false\n')),
        ).isHardwareConnected(),
        isFalse,
      );
    });

    test('nội dung lạ -> badResponse', () async {
      final api = makeApi(FakeAdapter((_) => const FakeReply(200, 'hmm')));
      expect(
        await errorOf(api.isHardwareConnected()),
        BlynkErrorKind.badResponse,
      );
    });
  });

  group('map lỗi', () {
    Future<BlynkErrorKind> kindFor(FakeReply r) =>
        errorOf(makeApi(FakeAdapter((_) => r)).getRaw([1]));

    test('mã trạng thái', () async {
      expect(
        await kindFor(
          const FakeReply(400, '{"error":{"message":"Invalid token."}}'),
        ),
        BlynkErrorKind.invalidToken,
      );
      expect(
        await kindFor(const FakeReply(400, 'Wrong pin')),
        BlynkErrorKind.invalidPin,
      );
      expect(
        await kindFor(const FakeReply(401, '')),
        BlynkErrorKind.invalidToken,
      );
      expect(
        await kindFor(const FakeReply(403, '')),
        BlynkErrorKind.invalidToken,
      );
      expect(
        await kindFor(const FakeReply(429, '')),
        BlynkErrorKind.rateLimited,
      );
      expect(await kindFor(const FakeReply(503, '')), BlynkErrorKind.server);
      expect(
        await kindFor(const FakeReply(404, '')),
        BlynkErrorKind.badResponse,
      );
      expect(await kindFor(const FakeReply.network()), BlynkErrorKind.network);
    });

    test('ngoại lệ không chứa token', () async {
      final api = makeApi(
        FakeAdapter((_) => const FakeReply.network()),
        token: 'SECRET-TOKEN-123',
      );
      try {
        await api.getRaw([1]);
      } on BlynkException catch (e) {
        expect(e.toString(), isNot(contains('SECRET')));
      }
    });
  });

  group('test() - Kiểm tra kết nối', () {
    const pins = PinMap(rpm: 3, temperature: 4);

    test('thành công: đọc thử được giá trị', () async {
      final a = FakeAdapter(
        (u) => u.path.endsWith('isHardwareConnected')
            ? const FakeReply(200, 'true')
            : const FakeReply(200, '{"v3":"1450","v4":"42.5"}'),
      );
      final r = await makeApi(a).test(pins);
      expect(r.error, isNull);
      expect(r.hardwareOnline, isTrue);
      expect(r.rpm, 1450);
      expect(r.temperature, 42.5);
    });

    test('token sai', () async {
      final a = FakeAdapter((_) => const FakeReply(400, 'Invalid token'));
      expect((await makeApi(a).test(pins)).error, BlynkErrorKind.invalidToken);
    });

    test('chưa điền pin bắt buộc: chỉ kiểm tra token + online', () async {
      final a = FakeAdapter((_) => const FakeReply(200, 'false'));
      final r = await makeApi(a).test(const PinMap());
      expect(r.error, isNull);
      expect(r.hardwareOnline, isFalse);
      expect(r.rpm, isNull);
      expect(a.calls('get'), isEmpty);
    });
  });
}
