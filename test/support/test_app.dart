import 'dart:math';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_app/app/providers.dart';
import 'package:tracking_app/data/local/memory_history_store.dart';
import 'package:tracking_app/data/local/settings_store.dart';
import 'package:tracking_app/data/repositories/mock_repository.dart';
import 'package:tracking_app/domain/device_issue.dart';

/// Mock chạy chậm, không rớt mạng, không lỗi lệnh - cho test giao diện.
class TestRepository extends MockRepository {
  TestRepository({
    this.issue = DeviceIssue.none,
    super.store,
    super.interval = const Duration(milliseconds: 100),
  }) : super(
         commandDelay: Duration.zero,
         failureRate: 0,
         simulateDropouts: false,
         random: Random(7),
       );

  final DeviceIssue issue;

  /// Giả lập thiết bị tự tắt/bật động cơ (không qua lệnh từ app).
  set simulatedMotorEnabled(bool v) => sim.motorEnabled = v;

  int pauses = 0;
  int resumes = 0;

  @override
  Stream<DeviceIssue> issueStream() => Stream.value(issue);

  @override
  void pause() {
    pauses++;
    super.pause();
  }

  @override
  void resume() {
    resumes++;
    super.resume();
  }
}

/// Override chuẩn cho mọi test giao diện: không đụng đĩa, mạng hay keystore.
Future<List<Override>> baseOverrides({
  Map<String, Object> prefs = const {},
  SecretStore? secrets,
  String? token,
  MemoryHistoryStore? store,
  TestRepository? repo,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final historyStore = store ?? MemoryHistoryStore();
  return [
    sharedPreferencesProvider.overrideWithValue(p),
    secretStoreProvider.overrideWithValue(secrets ?? MemorySecretStore()),
    initialTokenProvider.overrideWithValue(token),
    historyStoreProvider.overrideWithValue(historyStore),
    if (repo != null) deviceRepositoryProvider.overrideWithValue(repo),
  ];
}
