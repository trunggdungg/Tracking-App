import '../../domain/thresholds.dart';
import '../blynk/blynk_config.dart';
import '../blynk/pin_map.dart';

/// Toàn bộ cài đặt người dùng (trừ token, được cất riêng trong secure storage).
class AppSettings {
  const AppSettings({
    this.useMock = true,
    this.host = kDefaultBlynkHost,
    this.pollSeconds = 2,
    this.retentionDays = 30,
    this.thresholds = const Thresholds(),
    this.pinMap = const PinMap(),
  });

  /// true = dùng dữ liệu giả (MockRepository).
  final bool useMock;
  final String host;

  /// Chu kỳ polling: 1, 2 hoặc 5 giây.
  final int pollSeconds;

  /// Tự xóa lịch sử cũ hơn ngần ấy ngày.
  final int retentionDays;
  final Thresholds thresholds;
  final PinMap pinMap;

  static const pollOptions = [1, 2, 5];

  AppSettings copyWith({
    bool? useMock,
    String? host,
    int? pollSeconds,
    int? retentionDays,
    Thresholds? thresholds,
    PinMap? pinMap,
  }) => AppSettings(
    useMock: useMock ?? this.useMock,
    host: host ?? this.host,
    pollSeconds: pollSeconds ?? this.pollSeconds,
    retentionDays: retentionDays ?? this.retentionDays,
    thresholds: thresholds ?? this.thresholds,
    pinMap: pinMap ?? this.pinMap,
  );
}
