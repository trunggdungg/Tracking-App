import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/data/local/memory_history_store.dart';
import 'package:tracking_app/domain/alert_event.dart';
import 'package:tracking_app/domain/telemetry_data.dart';
import 'package:tracking_app/features/history/history_providers.dart';
import 'package:tracking_app/main.dart';

import '../support/test_app.dart';

void main() {
  group('resolveRange', () {
    final now = DateTime(2026, 3, 15, 14, 30);

    test('1 giờ, 7 ngày tính lùi từ bây giờ', () {
      final h = resolveRange(const HistorySelection(HistoryPreset.hour), now);
      expect(h.to, now);
      expect(h.from, DateTime(2026, 3, 15, 13, 30));
      final w = resolveRange(const HistorySelection(HistoryPreset.week), now);
      expect(w.from, DateTime(2026, 3, 8, 14, 30));
    });

    test('hôm nay bắt đầu từ 00:00', () {
      final r = resolveRange(const HistorySelection(HistoryPreset.today), now);
      expect(r.from, DateTime(2026, 3, 15));
      expect(r.to, now);
    });

    test('tùy chọn dùng đúng khoảng đã chọn', () {
      final r = resolveRange(
        HistorySelection(
          HistoryPreset.custom,
          customFrom: DateTime(2026, 1, 1),
          customTo: DateTime(2026, 1, 2),
        ),
        now,
      );
      expect(r.from, DateTime(2026, 1, 1));
      expect(r.to, DateTime(2026, 1, 2));
    });
  });

  testWidgets('tab Lịch sử hiển thị biểu đồ và danh sách cảnh báo từ kho lưu', (
    tester,
  ) async {
    final store = MemoryHistoryStore();
    final now = DateTime.now();
    await store.insertTelemetry([
      for (var i = 0; i < 20; i++)
        TelemetryData(
          timestamp: now.subtract(Duration(minutes: 20 - i)),
          rpm: 1400 + i.toDouble(),
          temperature: 40 + i.toDouble(),
        ),
    ]);
    await store.insertAlert(
      AlertEvent(
        timestamp: now.subtract(const Duration(minutes: 5)),
        level: WarningLevel.danger,
        type: AlertType.overheat,
        value: 83.4,
      ),
    );

    final repo = TestRepository(
      store: store,
      interval: const Duration(seconds: 30), // không sinh thêm mẫu trong test
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(store: store, repo: repo),
        child: const MotorMonitorApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Lịch sử'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Khoảng thời gian'), findsOneWidget);
    // ListView dựng lười: cuộn xuống tới thẻ cảnh báo.
    await tester.scrollUntilVisible(
      find.text('Sự kiện cảnh báo (1)'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sự kiện cảnh báo (1)'), findsOneWidget);
    expect(find.text('Quá nhiệt'), findsOneWidget);
    expect(find.text('83.4 °C'), findsOneWidget);

    // Cuộn lên, đổi sang 7 ngày: dữ liệu vẫn còn và không crash.
    await tester.scrollUntilVisible(
      find.text('7 ngày'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('7 ngày'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('20 điểm'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(repo.dispose());
  });
}
