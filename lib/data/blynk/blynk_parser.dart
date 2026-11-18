import 'dart:convert';

import '../../domain/telemetry_data.dart';
import 'pin_map.dart';

// ⚠️ ĐỊNH DẠNG PHẢN HỒI CHƯA ĐƯỢC ĐỐI CHIẾU VỚI DOCS BLYNK (không truy cập được
// docs.blynk.io khi viết). Parser vì vậy chấp nhận mọi dạng hợp lý:
//   - nhiều pin:  {"v3":"1450","v4":42.5}   (giá trị là số hoặc chuỗi)
//   - một pin:    1450                      (chuỗi thô, không phải JSON)
//   - một pin mảng / nhiều pin có giá trị mảng: lấy phần tử đầu
// Cần thử với thiết bị thật (nút "Kiểm tra kết nối" trong Cài đặt).

class BlynkParseException implements Exception {
  const BlynkParseException(this.message);
  final String message;
  @override
  String toString() => 'BlynkParseException: $message';
}

/// Biến phản hồi của `/external/api/get` thành {số pin -> giá trị thô}.
Map<int, Object?> parseGetResponse(String body, List<int> requested) {
  final text = body.trim();
  if (text.isEmpty) throw const BlynkParseException('Phản hồi rỗng');

  if (text.startsWith('{')) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const BlynkParseException('JSON không hợp lệ');
    }
    if (decoded is! Map) {
      throw const BlynkParseException('Không phải đối tượng JSON');
    }
    final out = <int, Object?>{};
    decoded.forEach((k, v) {
      final m = RegExp(r'^v(\d+)$', caseSensitive: false).firstMatch('$k');
      if (m != null) out[int.parse(m.group(1)!)] = v;
    });
    return out;
  }

  // Phản hồi thô chỉ có nghĩa khi hỏi đúng một pin.
  if (requested.length == 1) {
    Object? value = text;
    if (text.startsWith('[')) {
      try {
        value = jsonDecode(text);
      } on FormatException {
        // giữ nguyên là chuỗi
      }
    }
    return {requested.single: value};
  }
  throw const BlynkParseException('Không đọc được phản hồi nhiều pin');
}

/// Chuyển giá trị thô sang số; null nếu không đọc được.
double? asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  if (v is String) return double.tryParse(v.trim().replaceAll(',', '.'));
  if (v is List && v.isNotEmpty) return asDouble(v.first);
  return null;
}

String? _asText(Object? v) {
  if (v == null) return null;
  if (v is List) return v.isEmpty ? null : _asText(v.first);
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

/// Đèn cảnh báo của thiết bị: 0 an toàn, 1 chú ý, từ 2 nguy hiểm.
/// (Giả định - xác nhận lại với dashboard thật của bạn.)
WarningLevel warningLevelFromLamp(double value) {
  if (value <= 0) return WarningLevel.ok;
  if (value < 2) return WarningLevel.warn;
  return WarningLevel.danger;
}

/// Dựng mẫu đo từ giá trị pin. Trả về null nếu thiếu tốc độ hoặc nhiệt độ
/// (khi đó coi như chu kỳ này không có dữ liệu mới).
TelemetryData? buildTelemetry(
  Map<int, Object?> values,
  PinMap pins,
  DateTime now,
) {
  double? read(int? pin) => pin == null ? null : asDouble(values[pin]);

  final rpm = read(pins.rpm);
  final temperature = read(pins.temperature);
  if (rpm == null || temperature == null) return null;

  final lamp = read(pins.warningLamp);
  final fault = pins.fault == null ? null : _asText(values[pins.fault]);
  final buzzer = read(pins.buzzer);
  final motor = read(pins.motorSwitch);

  return TelemetryData(
    timestamp: now,
    rpm: rpm,
    temperature: temperature,
    vibration: read(pins.vibration),
    current: read(pins.current),
    healthPercent: read(pins.health),
    fault: (fault == null || fault == '0') ? null : fault,
    warningLevel: lamp == null ? WarningLevel.ok : warningLevelFromLamp(lamp),
    buzzerOn: buzzer != null && buzzer > 0,
    motorOn: motor == null ? null : motor > 0,
  );
}
