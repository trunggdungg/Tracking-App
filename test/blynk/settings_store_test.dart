import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracking_app/data/blynk/pin_map.dart';
import 'package:tracking_app/data/local/app_settings.dart';
import 'package:tracking_app/data/local/settings_store.dart';
import 'package:tracking_app/domain/thresholds.dart';

Future<SettingsStore> storeWith(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsStore(await SharedPreferences.getInstance());
}

void main() {
  test('chưa lưu gì thì trả về mặc định', () async {
    final s = (await storeWith({})).load();
    expect(s.useMock, isTrue);
    expect(s.host, 'blynk.cloud');
    expect(s.pollSeconds, 2);
    expect(s.retentionDays, 30);
    expect(s.thresholds, const Thresholds());
    expect(s.pinMap, const PinMap());
  });

  test('lưu rồi nạp lại đủ mọi trường', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore(prefs);
    await store.save(
      const AppSettings(
        useMock: false,
        host: 'https://sgp1.blynk.cloud/',
        pollSeconds: 5,
        retentionDays: 90,
        thresholds: Thresholds(
          rpmLow: 500,
          rpmHigh: 1700,
          rpmMax: 2500,
          tempWarn: 55.5,
          tempDanger: 75,
        ),
        pinMap: PinMap(rpm: 10, temperature: 11, vibration: 12, buzzerMute: 20),
      ),
    );

    final back = SettingsStore(prefs).load();
    expect(back.useMock, isFalse);
    expect(
      back.host,
      'sgp1.blynk.cloud',
      reason: 'host được chuẩn hóa khi lưu',
    );
    expect(back.pollSeconds, 5);
    expect(back.retentionDays, 90);
    expect(back.thresholds.tempWarn, 55.5);
    expect(back.thresholds.rpmMax, 2500);
    expect(back.pinMap.rpm, 10);
    expect(back.pinMap.vibration, 12);
    expect(back.pinMap.buzzerMute, 20);
  });

  test(
    'xóa trắng một pin thì nạp lại là null, không quay về mặc định',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = SettingsStore(prefs);
      // V0 mặc định là 0; người dùng xóa trắng -> phải giữ là null.
      await store.save(
        const AppSettings(
          pinMap: PinMap(motorSwitch: null, rpm: 3, temperature: 4),
        ),
      );
      expect(SettingsStore(prefs).load().pinMap.motorSwitch, isNull);

      // Điền lại thì lấy giá trị mới.
      await store.save(
        const AppSettings(
          pinMap: PinMap(motorSwitch: 7, rpm: 3, temperature: 4),
        ),
      );
      expect(SettingsStore(prefs).load().pinMap.motorSwitch, 7);
    },
  );

  test('token KHÔNG được ghi vào SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SettingsStore(prefs).save(const AppSettings());
    expect(
      prefs.getKeys().where((k) => k.toLowerCase().contains('token')),
      isEmpty,
    );
  });

  test('MemorySecretStore: lưu, xóa, cắt khoảng trắng', () async {
    final s = MemorySecretStore();
    expect(await s.readToken(), isNull);
    await s.writeToken('  abc  ');
    expect(await s.readToken(), 'abc');
    await s.writeToken('   ');
    expect(await s.readToken(), isNull);
  });
}
