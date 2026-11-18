import 'package:flutter/material.dart';

import '../domain/telemetry_data.dart';

/// Màu có ý nghĩa: xanh = ổn, vàng = gần ngưỡng, đỏ = vượt ngưỡng.
@immutable
class StatusPalette extends ThemeExtension<StatusPalette> {
  const StatusPalette({
    required this.ok,
    required this.warn,
    required this.danger,
    required this.speed,
    required this.temperature,
    required this.muted,
  });

  final Color ok;
  final Color warn;
  final Color danger;

  /// Màu chuỗi dữ liệu tốc độ (gauge + biểu đồ).
  final Color speed;

  /// Màu chuỗi dữ liệu nhiệt độ (gauge + biểu đồ).
  final Color temperature;

  /// Màu xám khi mất kết nối / không có dữ liệu.
  final Color muted;

  Color forLevel(WarningLevel level) => switch (level) {
    WarningLevel.ok => ok,
    WarningLevel.warn => warn,
    WarningLevel.danger => danger,
  };

  @override
  StatusPalette copyWith({
    Color? ok,
    Color? warn,
    Color? danger,
    Color? speed,
    Color? temperature,
    Color? muted,
  }) => StatusPalette(
    ok: ok ?? this.ok,
    warn: warn ?? this.warn,
    danger: danger ?? this.danger,
    speed: speed ?? this.speed,
    temperature: temperature ?? this.temperature,
    muted: muted ?? this.muted,
  );

  @override
  StatusPalette lerp(StatusPalette? other, double t) {
    if (other == null) return this;
    return StatusPalette(
      ok: Color.lerp(ok, other.ok, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      speed: Color.lerp(speed, other.speed, t)!,
      temperature: Color.lerp(temperature, other.temperature, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  StatusPalette get palette => Theme.of(this).extension<StatusPalette>()!;
}

const _radius = 12.0;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark
      ? const ColorScheme.dark(
          primary: Color(0xFF5AA0F0),
          surface: Color(0xFF161616),
          onSurface: Color(0xFFE6E6E6),
          onSurfaceVariant: Color(0xFFA8A8A8),
          outline: Color(0xFF3A3A3A),
          outlineVariant: Color(0xFF4A4A4A),
          secondaryContainer: Color(0xFF1F3A5F),
          onSecondaryContainer: Color(0xFFBBD7FA),
          error: Color(0xFFD13D3D),
        )
      : const ColorScheme.light(
          primary: Color(0xFF1F6FD1),
          surface: Color(0xFFF6F6F4),
          onSurface: Color(0xFF1A1A1A),
          onSurfaceVariant: Color(0xFF5F5F5F),
          outline: Color(0xFFD0D0CC),
          outlineVariant: Color(0xFFC4C4C0),
          secondaryContainer: Color(0xFFD6E4F8),
          onSecondaryContainer: Color(0xFF0B3A7A),
          error: Color(0xFFC62828),
        );

  final palette = dark
      ? const StatusPalette(
          ok: Color(0xFF2EA043),
          warn: Color(0xFFE3B341),
          danger: Color(0xFFD13D3D),
          speed: Color(0xFF3B8EEA),
          temperature: Color(0xFFF0A02B),
          muted: Color(0xFF6B6B6B),
        )
      : const StatusPalette(
          ok: Color(0xFF1A7F37),
          warn: Color(0xFF9A6700),
          danger: Color(0xFFC62828),
          speed: Color(0xFF1F6FD1),
          temperature: Color(0xFFD97706),
          muted: Color(0xFF9A9A9A),
        );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_radius),
    side: BorderSide(color: scheme.outline),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [palette],
    // Phẳng, viền mảnh, không đổ bóng.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF1B1B1A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: shape,
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
    ),
  );
}
