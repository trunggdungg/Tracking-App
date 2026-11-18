import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/thresholds.dart';
import 'app_settings.dart';
import '../blynk/blynk_config.dart';
import '../blynk/pin_map.dart';

/// Lưu cài đặt thường vào shared_preferences.
class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  AppSettings load() {
    const d = AppSettings();
    const dt = Thresholds();
    double t(String k, double def) => _prefs.getDouble('thr.$k') ?? def;

    // Khóa pin chưa từng lưu -> dùng mặc định; đã lưu "trống" -> null.
    final pins = <String, int?>{};
    final defaults = const PinMap().toMap();
    for (final f in PinMap.fields) {
      final key = 'pin.${f.key}';
      pins[f.key] = _prefs.containsKey(key)
          ? _prefs.getInt(key)
          : _prefs.containsKey('$key.empty')
          ? null
          : defaults[f.key];
    }

    return AppSettings(
      useMock: _prefs.getBool('useMock') ?? kDefaultUseMock,
      host: _prefs.getString('host') ?? d.host,
      pollSeconds: _prefs.getInt('pollSeconds') ?? d.pollSeconds,
      retentionDays: _prefs.getInt('retentionDays') ?? d.retentionDays,
      thresholds: Thresholds(
        rpmLow: t('rpmLow', dt.rpmLow),
        rpmHigh: t('rpmHigh', dt.rpmHigh),
        rpmMax: t('rpmMax', dt.rpmMax),
        tempWarn: t('tempWarn', dt.tempWarn),
        tempDanger: t('tempDanger', dt.tempDanger),
        tempMax: t('tempMax', dt.tempMax),
        vibrationDanger: t('vibrationDanger', dt.vibrationDanger),
      ),
      pinMap: PinMap.fromMap(pins),
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setBool('useMock', s.useMock);
    await _prefs.setString('host', normalizeHost(s.host));
    await _prefs.setInt('pollSeconds', s.pollSeconds);
    await _prefs.setInt('retentionDays', s.retentionDays);

    final thr = {
      'rpmLow': s.thresholds.rpmLow,
      'rpmHigh': s.thresholds.rpmHigh,
      'rpmMax': s.thresholds.rpmMax,
      'tempWarn': s.thresholds.tempWarn,
      'tempDanger': s.thresholds.tempDanger,
      'tempMax': s.thresholds.tempMax,
      'vibrationDanger': s.thresholds.vibrationDanger,
    };
    for (final e in thr.entries) {
      await _prefs.setDouble('thr.${e.key}', e.value);
    }

    for (final e in s.pinMap.toMap().entries) {
      final key = 'pin.${e.key}';
      final v = e.value;
      if (v == null) {
        // Lưu dấu "trống" để phân biệt với "chưa từng cấu hình".
        await _prefs.setString('$key.empty', '1');
        await _prefs.remove(key);
      } else {
        await _prefs.setInt(key, v);
        await _prefs.remove('$key.empty');
      }
    }
  }
}

/// Nơi cất token. Tách interface để test không cần secure storage thật.
abstract class SecretStore {
  Future<String?> readToken();
  Future<void> writeToken(String? token);
}

/// Token lưu trong Keystore (Android) qua flutter_secure_storage.
class FlutterSecretStore implements SecretStore {
  FlutterSecretStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'blynk_auth_token';

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> writeToken(String? token) async {
    if (token == null || token.trim().isEmpty) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: token.trim());
    }
  }
}

class MemorySecretStore implements SecretStore {
  String? _token;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> writeToken(String? token) async =>
      _token = (token == null || token.trim().isEmpty) ? null : token.trim();
}
