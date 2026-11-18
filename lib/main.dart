import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_shell.dart';
import 'app/settings_providers.dart';
import 'data/local/settings_store.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp trước cài đặt và token để UI không có trạng thái "đang tải cài đặt".
  final prefs = await SharedPreferences.getInstance();
  String? token;
  try {
    token = await FlutterSecretStore().readToken();
  } catch (_) {
    // Keystore lỗi (ví dụ sau khi khôi phục máy): coi như chưa có token,
    // người dùng nhập lại trong Cài đặt.
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialTokenProvider.overrideWithValue(token),
      ],
      child: const MotorMonitorApp(),
    ),
  );
}

class MotorMonitorApp extends StatelessWidget {
  const MotorMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Giám sát động cơ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // Tiếng Việt cho bộ chọn ngày giờ và các thành phần Material.
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
