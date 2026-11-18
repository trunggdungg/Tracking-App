import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/app_settings.dart';
import '../data/local/settings_store.dart';
import '../domain/thresholds.dart';

/// Phải được override trong main() sau khi đã nạp SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Cần override sharedPreferencesProvider'),
);

final secretStoreProvider = Provider<SecretStore>(
  (ref) => FlutterSecretStore(),
);

/// Token đã đọc từ secure storage trước khi chạy app (override trong main()).
final initialTokenProvider = Provider<String?>((ref) => null);

/// Cài đặt người dùng. Đọc đồng bộ từ SharedPreferences nên không có trạng thái "đang tải".
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      SettingsStore(ref.read(sharedPreferencesProvider)).load();

  /// Cập nhật state NGAY (đồng bộ) rồi mới ghi xuống đĩa.
  Future<void> save(AppSettings next) async {
    state = next;
    await SettingsStore(ref.read(sharedPreferencesProvider)).save(next);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Token Blynk. Chỉ nằm trong bộ nhớ + secure storage, không bao giờ vào
/// SharedPreferences hay log.
class TokenNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(initialTokenProvider);

  Future<void> save(String? token) async {
    final clean = (token == null || token.trim().isEmpty) ? null : token.trim();
    state = clean;
    await ref.read(secretStoreProvider).writeToken(clean);
  }
}

final tokenProvider = NotifierProvider<TokenNotifier, String?>(
  TokenNotifier.new,
);

// Các provider dẫn xuất: widget chỉ rebuild khi đúng phần nó dùng đổi.
final useMockProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((s) => s.useMock)),
);

final thresholdsProvider = Provider<Thresholds>(
  (ref) => ref.watch(settingsProvider.select((s) => s.thresholds)),
);

final retentionDaysProvider = Provider<int>(
  (ref) => ref.watch(settingsProvider.select((s) => s.retentionDays)),
);
