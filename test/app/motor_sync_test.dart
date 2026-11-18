import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/app/providers.dart';

import '../support/test_app.dart';

void main() {
  // Hồi quy: telemetryProvider và motorControllerProvider từng phụ thuộc vòng
  // vào nhau (CircularDependencyError) khiến luồng dữ liệu hỏng hoàn toàn.
  test(
    'telemetryProvider đọc được trạng thái động cơ mà không bị vòng phụ thuộc',
    () async {
      final repo = TestRepository();
      final c = ProviderContainer(overrides: await baseOverrides(repo: repo));
      addTearDown(() {
        c.dispose();
        repo.dispose();
      });
      c.read(motorSyncProvider);
      c.listen(telemetryProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final t = c.read(telemetryProvider);
      expect(t.hasError, isFalse, reason: '${t.error}');
      expect(t.value?.rpm, isNotNull);
    },
  );

  test('công tắc động cơ đồng bộ theo trạng thái thiết bị báo', () async {
    final repo = TestRepository();
    final c = ProviderContainer(overrides: await baseOverrides(repo: repo));
    addTearDown(() {
      c.dispose();
      repo.dispose();
    });
    c.read(motorSyncProvider);
    c.listen(telemetryProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(c.read(motorControllerProvider).enabled, isTrue);

    // Thiết bị tắt động cơ (không phải từ app) -> công tắc phải theo.
    repo.simulatedMotorEnabled = false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(c.read(motorControllerProvider).enabled, isFalse);
  });

  test('đang gửi lệnh thì không bị đồng bộ đè lên', () async {
    final repo = TestRepository();
    final c = ProviderContainer(overrides: await baseOverrides(repo: repo));
    addTearDown(() {
      c.dispose();
      repo.dispose();
    });
    final notifier = c.read(motorControllerProvider.notifier);
    notifier.syncFromDevice(false);
    expect(c.read(motorControllerProvider).enabled, isFalse);
    notifier.syncFromDevice(true);
    expect(c.read(motorControllerProvider).enabled, isTrue);
  });
}
