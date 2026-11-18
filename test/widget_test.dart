import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracking_app/main.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('màn hình Trực tiếp hiển thị dữ liệu giả', (tester) async {
    final repo = TestRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(repo: repo),
        child: const MotorMonitorApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Giám sát động cơ'), findsOneWidget);
    expect(find.text('Đã kết nối'), findsOneWidget);
    expect(find.text('vòng/phút'), findsOneWidget);
    expect(find.text('Tốc độ ổn định'), findsOneWidget);
    expect(find.text('Động cơ'), findsOneWidget);

    // Gỡ widget để dừng các timer trước khi test kết thúc.
    await tester.pumpWidget(const SizedBox.shrink());
    unawaited(repo.dispose()); // hủy timer ngay (phần đồng bộ của dispose)
  });
}
