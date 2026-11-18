import 'pin_map.dart';

const kDefaultBlynkHost = 'blynk.cloud';

/// Các máy chủ theo vùng để chọn nhanh trong Cài đặt.
const kBlynkHosts = [
  'blynk.cloud',
  'sgp1.blynk.cloud',
  'blr1.blynk.cloud',
  'fra1.blynk.cloud',
  'lon1.blynk.cloud',
  'ny3.blynk.cloud',
];

/// Chấp nhận cả "https://sgp1.blynk.cloud/" lẫn "sgp1.blynk.cloud".
String normalizeHost(String input) {
  var h = input.trim();
  h = h.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  h = h.replaceAll(RegExp(r'/+$'), '');
  return h.isEmpty ? kDefaultBlynkHost : h;
}

class BlynkConfig {
  const BlynkConfig({
    required this.host,
    required this.token,
    required this.pollInterval,
    required this.pinMap,
  });

  final String host;

  /// Lấy từ secure storage, tuyệt đối không hardcode, không log.
  final String? token;
  final Duration pollInterval;
  final PinMap pinMap;

  bool get hasToken => token != null && token!.trim().isNotEmpty;

  /// Không in token ra, kể cả khi bị log nhầm.
  @override
  String toString() => 'BlynkConfig(host: $host, poll: $pollInterval)';
}
