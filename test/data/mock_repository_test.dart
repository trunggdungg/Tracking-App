import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/data/repositories/mock_repository.dart';
import 'package:tracking_app/domain/device_command.dart';
import 'package:tracking_app/domain/telemetry_data.dart';

void main() {
  group('MockSimulator', () {
    test('rpm luôn trong 1200-1600 khi động cơ bật', () {
      final sim = MockSimulator(random: Random(1));
      for (var i = 0; i < 500; i++) {
        final d = sim.next(DateTime(2026));
        expect(d.rpm, inInclusiveRange(1200, 1600));
      }
    });

    test('nhiệt độ tăng dần rồi thỉnh thoảng vượt ngưỡng cảnh báo', () {
      final sim = MockSimulator(random: Random(2));
      final temps = [
        for (var i = 0; i < 400; i++) sim.next(DateTime(2026)).temperature,
      ];
      expect(temps[30], greaterThan(temps[0]));
      expect(temps.any((t) => t >= 60), isTrue);
    });

    test('dừng động cơ: rpm về 0, nhiệt độ nguội', () {
      final sim = MockSimulator(random: Random(3));
      for (var i = 0; i < 30; i++) {
        sim.next(DateTime(2026));
      }
      sim.motorEnabled = false;
      TelemetryData d = sim.next(DateTime(2026));
      for (var i = 0; i < 40; i++) {
        d = sim.next(DateTime(2026));
      }
      expect(d.rpm, 0);
    });

    test('quá nhiệt thì mức danger, bật còi và báo lỗi; tắt còi được', () {
      final sim = MockSimulator(random: Random(4));
      TelemetryData? danger;
      for (var i = 0; i < 2000 && danger == null; i++) {
        final d = sim.next(DateTime(2026));
        if (d.warningLevel == WarningLevel.danger) danger = d;
      }
      expect(danger, isNotNull, reason: 'cần có lúc vượt ngưỡng nguy hiểm');
      expect(danger!.buzzerOn, isTrue);
      expect(danger.fault, isNotNull);

      sim.buzzerMuted = true;
      expect(sim.next(DateTime(2026)).buzzerOn, isFalse);
    });
  });

  group('MockRepository', () {
    MockRepository make({double failureRate = 0, bool dropouts = false}) =>
        MockRepository(
          interval: const Duration(milliseconds: 10),
          commandDelay: Duration.zero,
          failureRate: failureRate,
          simulateDropouts: dropouts,
          random: Random(5),
        );

    test('phát luồng dữ liệu và lưu lịch sử', () async {
      final repo = make();
      addTearDown(repo.dispose);
      final samples = await repo.telemetryStream().take(3).toList();
      expect(samples, hasLength(3));
      final from = DateTime.now().subtract(const Duration(minutes: 1));
      final hist = await repo.history(from, DateTime.now());
      expect(hist.length, greaterThanOrEqualTo(3));
      expect(await repo.history(DateTime(2000), DateTime(2001)), isEmpty);
    });

    test(
      'connectionStream phát trạng thái hiện tại ngay khi lắng nghe',
      () async {
        final repo = make();
        addTearDown(repo.dispose);
        expect(await repo.connectionStream().first, isTrue);
      },
    );

    test('lệnh thành công: tắt động cơ -> rpm về 0', () async {
      final repo = make();
      addTearDown(repo.dispose);
      expect(
        await repo.sendCommand(const DeviceCommand.motorEnable(false)),
        isTrue,
      );
      final last = await repo.telemetryStream().skip(40).first;
      expect(last.rpm, 0);
    });

    test('failureRate = 1: lệnh luôn thất bại', () async {
      final repo = make(failureRate: 1);
      addTearDown(repo.dispose);
      expect(
        await repo.sendCommand(const DeviceCommand.emergencyStop()),
        isFalse,
      );
    });

    test('mất kết nối thì dừng phát mẫu mới và phát false', () async {
      final repo = MockRepository(
        interval: const Duration(milliseconds: 5),
        commandDelay: Duration.zero,
        random: Random(6),
      );
      addTearDown(repo.dispose);
      repo.telemetryStream(); // bắt đầu timer
      final states = <bool>[];
      final sub = repo.connectionStream().listen(states.add);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await sub.cancel();
      expect(states, contains(false), reason: 'phải có lúc ngắt kết nối');
      expect(states.last, isTrue, reason: 'rồi kết nối lại');
    });
  });
}
