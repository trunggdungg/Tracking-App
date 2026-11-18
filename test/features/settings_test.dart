import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/app/providers.dart';
import 'package:tracking_app/data/local/settings_store.dart';
import 'package:tracking_app/data/repositories/blynk_repository.dart';
import 'package:tracking_app/data/repositories/mock_repository.dart';
import 'package:tracking_app/domain/device_issue.dart';
import 'package:tracking_app/main.dart';

import '../support/test_app.dart';

/// Danh sách cuộn của màn Cài đặt. (Không dùng `Scrollable.last` vì mỗi ô nhập chữ
/// cũng có một Scrollable bên trong.)
Finder settingsScrollable() => find
    .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
    .first;

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Cài đặt'));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Ô nhập theo nhãn: ô có nhãn trong khung (token, host) hoặc ô số có nhãn nằm
/// cạnh bên (pin, ngưỡng, số ngày).
Finder fieldFor(String label) {
  final decorated = find.widgetWithText(TextFormField, label);
  if (decorated.evaluate().isNotEmpty) return decorated;
  return find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
    matching: find.byType(TextFormField),
  );
}

Future<void> typeInto(WidgetTester tester, String label, String text) async {
  final field = fieldFor(label);
  await tester.scrollUntilVisible(field, 200, scrollable: settingsScrollable());
  await tester.enterText(field, text);
}

/// Bấm "Lưu cài đặt". Gọi thẳng onPressed của nút vì trong khung test 800x600
/// `tester.tap` không trúng được nút nằm sát đáy vùng cuộn (cảnh báo hit-test).
Future<void> tapSave(WidgetTester tester) async {
  final save = find.text('Lưu cài đặt');
  await tester.scrollUntilVisible(save, 300, scrollable: settingsScrollable());
  final button = tester.widget<FilledButton>(
    find.ancestor(of: save, matching: find.bySubtype<FilledButton>()),
  );
  button.onPressed!();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Gỡ cây widget, dừng mọi timer (repository, recorder) trước khi test kết thúc.
Future<void> teardown(
  WidgetTester tester,
  TestRepository repo, {
  ProviderContainer? container,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container?.dispose();
  unawaited(repo.dispose());
}

void main() {
  testWidgets('token được ẩn ký tự, có thể hiện bằng nút con mắt', (
    tester,
  ) async {
    final repo = TestRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(repo: repo, token: 'abc123'),
        child: const MotorMonitorApp(),
      ),
    );
    await openSettings(tester);

    TextField tokenField() => tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Auth Token'),
        matching: find.byType(TextField),
      ),
    );
    expect(tokenField().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(tokenField().obscureText, isFalse);
    await teardown(tester, repo);
  });

  testWidgets(
    'lưu cài đặt: pin vào SharedPreferences, token vào secure storage',
    (tester) async {
      final repo = TestRepository();
      final secrets = MemorySecretStore();
      final container = ProviderContainer(
        overrides: await baseOverrides(repo: repo, secrets: secrets),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MotorMonitorApp(),
        ),
      );
      await openSettings(tester);

      await typeInto(tester, 'Auth Token', '  MY-SECRET-TOKEN ');
      await typeInto(tester, 'Tốc độ (vòng/phút) *', '3');
      await typeInto(tester, 'Nhiệt độ (°C) *', '4');
      await typeInto(tester, 'Tự xóa dữ liệu cũ hơn', '60');
      await tapSave(tester);

      final s = container.read(settingsProvider);
      expect(s.pinMap.rpm, 3);
      expect(s.pinMap.temperature, 4);
      expect(s.retentionDays, 60);
      expect(container.read(retentionDaysProvider), 60);
      expect(container.read(tokenProvider), 'MY-SECRET-TOKEN');
      expect(await secrets.readToken(), 'MY-SECRET-TOKEN');

      // Token tuyệt đối không nằm trong SharedPreferences.
      final prefs = container.read(sharedPreferencesProvider);
      expect(
        prefs.getKeys().any((k) => k.toLowerCase().contains('token')),
        isFalse,
      );
      expect(prefs.getInt('pin.rpm'), 3);
      expect(find.text('Đã lưu cài đặt.'), findsOneWidget);
      await teardown(tester, repo, container: container);
    },
  );

  testWidgets('pin không hợp lệ thì báo lỗi và KHÔNG lưu', (tester) async {
    final repo = TestRepository();
    final container = ProviderContainer(
      overrides: await baseOverrides(repo: repo),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MotorMonitorApp(),
      ),
    );
    await openSettings(tester);

    await typeInto(tester, 'Tốc độ (vòng/phút) *', '999');
    await tapSave(tester);

    expect(find.text('0-255'), findsWidgets);
    expect(container.read(settingsProvider).pinMap.rpm, isNull);
    expect(find.text('Đã lưu cài đặt.'), findsNothing);
    await teardown(tester, repo, container: container);
  });

  testWidgets('pin bắt buộc để trống thì báo "Bắt buộc"', (tester) async {
    final repo = TestRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(repo: repo),
        child: const MotorMonitorApp(),
      ),
    );
    await openSettings(tester);
    await tapSave(tester);
    expect(find.text('Bắt buộc'), findsWidgets);
    await teardown(tester, repo);
  });

  testWidgets('ngưỡng mâu thuẫn (thấp >= cao) bị từ chối', (tester) async {
    final repo = TestRepository();
    final container = ProviderContainer(
      overrides: await baseOverrides(repo: repo),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MotorMonitorApp(),
      ),
    );
    await openSettings(tester);

    await typeInto(tester, 'Tốc độ (vòng/phút) *', '3');
    await typeInto(tester, 'Nhiệt độ (°C) *', '4');
    await typeInto(
      tester,
      'Tốc độ thấp',
      '1900',
    ); // >= tốc độ cao mặc định 1800
    await tapSave(tester);

    expect(find.text('Tốc độ thấp phải nhỏ hơn tốc độ cao.'), findsOneWidget);
    expect(container.read(settingsProvider).thresholds.rpmLow, 800);
    await teardown(tester, repo, container: container);
  });

  testWidgets('banner token sai dẫn tới màn hình Cài đặt', (tester) async {
    final repo = TestRepository(issue: DeviceIssue.invalidToken);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(repo: repo),
        child: const MotorMonitorApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Token không hợp lệ hoặc đã bị thu hồi.'), findsOneWidget);
    expect(
      find.text('Nguồn dữ liệu'),
      findsNothing,
      reason: 'đang ở tab Trực tiếp',
    );

    await tester.tap(find.text('Mở Cài đặt'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nguồn dữ liệu'), findsOneWidget);
    await teardown(tester, repo);
  });

  testWidgets('app vào nền thì tạm dừng lấy dữ liệu, quay về thì chạy lại', (
    tester,
  ) async {
    final repo = TestRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(repo: repo),
        child: const MotorMonitorApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final binding = tester.binding;
    // Flutter yêu cầu đi theo đúng thứ tự: resumed -> inactive -> hidden -> paused.
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(repo.pauses, 0, reason: 'inactive chưa coi là vào nền');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(repo.pauses, greaterThanOrEqualTo(1));
    expect(repo.resumes, 0);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(repo.resumes, 0, reason: 'chưa quay về hẳn');
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(repo.resumes, 1);
    await teardown(tester, repo);
  });

  group('chọn repository theo cài đặt', () {
    test('Mock -> Blynk khi tắt Mock, và repository cũ được dispose', () async {
      final container = ProviderContainer(overrides: await baseOverrides());
      addTearDown(container.dispose);

      expect(container.read(deviceRepositoryProvider), isA<MockRepository>());

      await container.read(tokenProvider.notifier).save('TOKEN');
      await container
          .read(settingsProvider.notifier)
          .save(container.read(settingsProvider).copyWith(useMock: false));
      expect(container.read(deviceRepositoryProvider), isA<BlynkRepository>());
    });

    test('đổi ngưỡng KHÔNG dựng lại repository', () async {
      final container = ProviderContainer(overrides: await baseOverrides());
      addTearDown(container.dispose);
      final before = container.read(deviceRepositoryProvider);
      final s = container.read(settingsProvider);
      await container
          .read(settingsProvider.notifier)
          .save(s.copyWith(thresholds: s.thresholds.copyWith(tempWarn: 50)));
      expect(
        identical(container.read(deviceRepositoryProvider), before),
        isTrue,
      );
      expect(container.read(thresholdsProvider).tempWarn, 50);
    });

    test('đổi ánh xạ pin hoặc chu kỳ thì dựng lại repository', () async {
      final container = ProviderContainer(overrides: await baseOverrides());
      addTearDown(container.dispose);
      final before = container.read(deviceRepositoryProvider);
      final s = container.read(settingsProvider);
      await container
          .read(settingsProvider.notifier)
          .save(s.copyWith(pollSeconds: 5));
      expect(
        identical(container.read(deviceRepositoryProvider), before),
        isFalse,
      );
    });
  });
}
