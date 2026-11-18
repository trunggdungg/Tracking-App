import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/data/blynk/blynk_api.dart';
import 'package:tracking_app/data/blynk/blynk_config.dart';
import 'package:tracking_app/data/blynk/pin_map.dart';
import 'package:tracking_app/data/local/memory_history_store.dart';
import 'package:tracking_app/data/repositories/blynk_repository.dart';
import 'package:tracking_app/domain/device_command.dart';
import 'package:tracking_app/domain/device_issue.dart';
import 'package:tracking_app/domain/telemetry_data.dart';

import '../support/fake_adapter.dart';

const pins = PinMap(rpm: 3, temperature: 4, buzzerMute: 9);
const poll = Duration(milliseconds: 20);

const okValues = FakeReply(200, '{"v0":"1","v3":"1450","v4":"42.5"}');

FakeReply serverOk(Uri u) => u.path.endsWith('isHardwareConnected')
    ? const FakeReply(200, 'true')
    : u.path.endsWith('/get')
    ? okValues
    : const FakeReply(200, '');

class Harness {
  Harness(
    FakeReply Function(Uri) handler, {
    PinMap pinMap = pins,
    String? token = 'TOK',
  }) : adapter = FakeAdapter(handler) {
    final config = BlynkConfig(
      host: 'blynk.cloud',
      token: token,
      pollInterval: poll,
      pinMap: pinMap,
    );
    repo = BlynkRepository(
      config: config,
      store: MemoryHistoryStore(),
      api: token == null
          ? null
          : BlynkApi(host: 'blynk.cloud', token: token, dio: fakeDio(adapter)),
    );
  }
  final FakeAdapter adapter;
  late final BlynkRepository repo;

  Future<void> dispose() => repo.dispose();
}

Future<void> wait([int ms = 150]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('nextDelay (backoff)', () {
    const base = Duration(seconds: 2);
    test('không lỗi thì đúng chu kỳ, lỗi liên tiếp thì gấp đôi dần', () {
      expect(BlynkRepository.nextDelay(base, 0), base);
      expect(BlynkRepository.nextDelay(base, 1), const Duration(seconds: 4));
      expect(BlynkRepository.nextDelay(base, 2), const Duration(seconds: 8));
      expect(BlynkRepository.nextDelay(base, 3), const Duration(seconds: 16));
    });

    test('tối đa 60 giây, kể cả khi lỗi rất nhiều lần', () {
      expect(BlynkRepository.nextDelay(base, 10), const Duration(seconds: 60));
      expect(
        BlynkRepository.nextDelay(base, 1000),
        const Duration(seconds: 60),
      );
    });
  });

  group('polling', () {
    test('phát dữ liệu và trạng thái kết nối khi thiết bị online', () async {
      final h = Harness(serverOk);
      addTearDown(h.dispose);
      final samples = <TelemetryData>[];
      h.repo.telemetryStream().listen(samples.add);
      final conn = <bool>[];
      h.repo.connectionStream().listen(conn.add);
      await wait();

      expect(samples, isNotEmpty);
      expect(samples.first.rpm, 1450);
      expect(samples.first.temperature, 42.5);
      expect(samples.first.motorOn, isTrue);
      expect(conn.last, isTrue);
      // mỗi chu kỳ gọi cả get lẫn isHardwareConnected
      expect(h.adapter.calls('get'), isNotEmpty);
      expect(h.adapter.calls('isHardwareConnected'), isNotEmpty);
      // pin đọc đúng theo PinMap (V0 công tắc, V3 tốc độ, V4 nhiệt độ)
      expect(h.adapter.calls('get').first.query, 'token=TOK&v0&v3&v4');
    });

    test('thiết bị offline: báo ngắt kết nối, KHÔNG phát dữ liệu cũ', () async {
      final h = Harness(
        (u) => u.path.endsWith('isHardwareConnected')
            ? const FakeReply(200, 'false')
            : okValues,
      );
      addTearDown(h.dispose);
      final samples = <TelemetryData>[];
      h.repo.telemetryStream().listen(samples.add);
      final conn = <bool>[];
      h.repo.connectionStream().listen(conn.add);
      await wait();
      expect(samples, isEmpty);
      expect(conn.last, isFalse);
    });

    test(
      'mất mạng đủ 3 chu kỳ thì ngắt kết nối, có mạng lại thì kết nối lại',
      () async {
        var down = false;
        final h = Harness(
          (u) => down ? const FakeReply.network() : serverOk(u),
        );
        addTearDown(h.dispose);
        final conn = <bool>[];
        h.repo.telemetryStream().listen((_) {});
        h.repo.connectionStream().listen(conn.add);
        await wait(100);
        expect(conn.last, isTrue);

        down = true;
        await wait(
          600,
        ); // đủ để backoff vẫn kịp 3 lần lỗi (20ms, 40ms, 80ms...)
        expect(conn.last, isFalse);

        down = false;
        await wait(1500); // backoff có thể đang chờ vài trăm ms
        expect(conn.last, isTrue);
      },
    );

    test(
      'lỗi mạng khi chưa đủ 3 chu kỳ thì chưa vội báo ngắt kết nối',
      () async {
        var calls = 0;
        final h = Harness((u) {
          calls++;
          return calls <= 2 ? serverOk(u) : const FakeReply.network();
        });
        addTearDown(h.dispose);
        final conn = <bool>[];
        h.repo.telemetryStream().listen((_) {});
        h.repo.connectionStream().listen(conn.add);
        await wait(
          100,
        ); // mới lỗi 2 lần liên tiếp (chu kỳ 20ms, rồi giãn 40ms, 80ms)
        final firstTrue = conn.indexOf(true);
        expect(firstTrue, isNonNegative, reason: 'đã kết nối ở chu kỳ đầu');
        expect(conn.skip(firstTrue), isNot(contains(false)));
      },
    );

    test(
      'thiếu tốc độ/nhiệt độ trong phản hồi tính là không có dữ liệu mới',
      () async {
        final h = Harness(
          (u) => u.path.endsWith('isHardwareConnected')
              ? const FakeReply(200, 'true')
              : const FakeReply(200, '{"v0":"1"}'),
        );
        addTearDown(h.dispose);
        final samples = <TelemetryData>[];
        h.repo.telemetryStream().listen(samples.add);
        await wait(400);
        expect(samples, isEmpty);
      },
    );

    test('không bao giờ có hai yêu cầu chồng nhau', () async {
      var inFlight = 0;
      var maxInFlight = 0;
      final h = Harness(serverOk);
      h.adapter.handler = (u) {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        inFlight--;
        return serverOk(u);
      };
      addTearDown(h.dispose);
      h.repo.telemetryStream().listen((_) {});
      await wait(200);
      // get và isHardwareConnected chạy song song nên tối đa 2, không hơn
      expect(maxInFlight, lessThanOrEqualTo(2));
    });
  });

  group('lỗi cấu hình / xác thực', () {
    Future<List<DeviceIssue>> issuesOf(Harness h) async {
      final issues = <DeviceIssue>[];
      h.repo.issueStream().listen(issues.add);
      h.repo.telemetryStream().listen((_) {});
      await wait();
      return issues;
    }

    test('token sai: báo invalidToken và DỪNG polling', () async {
      final h = Harness((_) => const FakeReply(400, 'Invalid token.'));
      addTearDown(h.dispose);
      final issues = await issuesOf(h);
      expect(issues.last, DeviceIssue.invalidToken);

      final before = h.adapter.requests.length;
      await wait(200);
      expect(
        h.adapter.requests.length,
        before,
        reason: 'không gọi lại khi token sai',
      );
    });

    test('pin sai: báo invalidPins và dừng polling', () async {
      final h = Harness((_) => const FakeReply(400, 'Wrong pin'));
      addTearDown(h.dispose);
      expect((await issuesOf(h)).last, DeviceIssue.invalidPins);
    });

    test('chưa có token: notConfigured, không gọi mạng', () async {
      final h = Harness(serverOk, token: null);
      addTearDown(h.dispose);
      expect((await issuesOf(h)).last, DeviceIssue.notConfigured);
      expect(h.adapter.requests, isEmpty);
    });

    test('chưa điền pin tốc độ/nhiệt độ: notConfigured', () async {
      final h = Harness(serverOk, pinMap: const PinMap());
      addTearDown(h.dispose);
      expect((await issuesOf(h)).last, DeviceIssue.notConfigured);
      expect(h.adapter.requests, isEmpty);
    });

    test(
      'hết hạn mức tin nhắn: báo quotaExceeded, KHÔNG dừng polling',
      () async {
        var limited = true;
        final h = Harness(
          (u) => limited
              ? const FakeReply(
                  400,
                  '{"error":{"message":"Messages limit reached!"}}',
                )
              : serverOk(u),
        );
        addTearDown(h.dispose);
        final issues = await issuesOf(h);
        expect(issues.last, DeviceIssue.quotaExceeded);

        // Hạn mức làm mới: app tự hồi phục, không cần khởi động lại.
        limited = false;
        await wait(1600); // chờ qua khoảng giãn (backoff)
        expect(issues.last, DeviceIssue.none);
      },
    );

    test('gửi lệnh khi hết hạn mức: false và báo quotaExceeded', () async {
      final h = Harness((_) => const FakeReply(400, 'Messages limit reached!'));
      addTearDown(h.dispose);
      final issues = <DeviceIssue>[];
      h.repo.issueStream().listen(issues.add);
      expect(
        await h.repo.sendCommand(const DeviceCommand.motorEnable(true)),
        isFalse,
      );
      await wait(20);
      expect(issues.last, DeviceIssue.quotaExceeded);
    });

    test('hoạt động bình thường thì issue là none', () async {
      final h = Harness(serverOk);
      addTearDown(h.dispose);
      expect((await issuesOf(h)).last, DeviceIssue.none);
    });
  });

  group('pause / resume (app vào nền / quay về)', () {
    test('pause dừng gọi mạng, resume gọi lại ngay', () async {
      final h = Harness(serverOk);
      addTearDown(h.dispose);
      h.repo.telemetryStream().listen((_) {});
      await wait(100);

      h.repo.pause();
      await wait(60); // chờ yêu cầu đang bay (nếu có) xong
      final paused = h.adapter.requests.length;
      await wait(200);
      expect(h.adapter.requests.length, paused);

      h.repo.resume();
      await wait(100);
      expect(h.adapter.requests.length, greaterThan(paused));
    });
  });

  group('sendCommand', () {
    Harness started() {
      final h = Harness(serverOk);
      addTearDown(h.dispose);
      return h;
    }

    Uri lastUpdate(Harness h) => h.adapter.calls('update').last;

    test('bật/tắt động cơ ghi vào pin motorSwitch (V0)', () async {
      final h = started();
      expect(
        await h.repo.sendCommand(const DeviceCommand.motorEnable(true)),
        isTrue,
      );
      expect(lastUpdate(h).query, 'token=TOK&v0=1');
      await h.repo.sendCommand(const DeviceCommand.motorEnable(false));
      expect(lastUpdate(h).query, 'token=TOK&v0=0');
    });

    test('dừng khẩn cấp: một lệnh duy nhất đặt V2=1 và V0=0', () async {
      final h = started();
      expect(
        await h.repo.sendCommand(const DeviceCommand.emergencyStop()),
        isTrue,
      );
      expect(h.adapter.calls('update'), hasLength(1));
      expect(lastUpdate(h).query, 'token=TOK&v2=1&v0=0');
    });

    test(
      'tắt còi dùng pin buzzerMute; chưa cấu hình pin thì trả về false',
      () async {
        final h = started();
        expect(
          await h.repo.sendCommand(const DeviceCommand.buzzerMute(true)),
          isTrue,
        );
        expect(lastUpdate(h).query, 'token=TOK&v9=1');

        final noBuzzer = Harness(
          serverOk,
          pinMap: const PinMap(rpm: 3, temperature: 4),
        );
        addTearDown(noBuzzer.dispose);
        expect(
          await noBuzzer.repo.sendCommand(const DeviceCommand.buzzerMute(true)),
          isFalse,
        );
        expect(noBuzzer.adapter.calls('update'), isEmpty);
      },
    );

    test('lỗi mạng hoặc máy chủ: trả về false, không ném', () async {
      final h = Harness((_) => const FakeReply(500, ''));
      addTearDown(h.dispose);
      expect(
        await h.repo.sendCommand(const DeviceCommand.motorEnable(true)),
        isFalse,
      );
      final net = Harness((_) => const FakeReply.network());
      addTearDown(net.dispose);
      expect(
        await net.repo.sendCommand(const DeviceCommand.motorEnable(true)),
        isFalse,
      );
    });

    test('token sai khi gửi lệnh: false và báo invalidToken', () async {
      final h = Harness((_) => const FakeReply(400, 'Invalid token'));
      addTearDown(h.dispose);
      final issues = <DeviceIssue>[];
      h.repo.issueStream().listen(issues.add);
      expect(
        await h.repo.sendCommand(const DeviceCommand.motorEnable(true)),
        isFalse,
      );
      await wait(20);
      expect(issues.last, DeviceIssue.invalidToken);
    });

    test('không cấu hình thì không gửi được lệnh', () async {
      final h = Harness(serverOk, token: null);
      addTearDown(h.dispose);
      expect(
        await h.repo.sendCommand(const DeviceCommand.emergencyStop()),
        isFalse,
      );
    });
  });

  test('history đọc từ HistoryStore', () async {
    final store = MemoryHistoryStore();
    await store.insertTelemetry([
      TelemetryData(
        timestamp: DateTime(2026, 1, 1, 12),
        rpm: 1,
        temperature: 2,
      ),
    ]);
    final repo = BlynkRepository(
      config: const BlynkConfig(
        host: 'blynk.cloud',
        token: null,
        pollInterval: poll,
        pinMap: pins,
      ),
      store: store,
    );
    addTearDown(repo.dispose);
    final rows = await repo.history(DateTime(2026), DateTime(2027));
    expect(rows, hasLength(1));
  });
}
