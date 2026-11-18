import 'package:dio/dio.dart';

import '../../domain/telemetry_data.dart';
import 'blynk_config.dart';
import 'blynk_parser.dart';
import 'pin_map.dart';

enum BlynkErrorKind {
  invalidToken,
  invalidPin,
  rateLimited,
  server,
  timeout,
  network,
  badResponse,
}

/// Lỗi gọi Blynk. CỐ Ý không chứa URL hay thông báo gốc của dio
/// vì chúng có thể kèm token.
class BlynkException implements Exception {
  const BlynkException(this.kind, [this.statusCode]);
  final BlynkErrorKind kind;
  final int? statusCode;
  @override
  String toString() => 'BlynkException($kind, $statusCode)';
}

/// Kết quả "Kiểm tra kết nối" trong Cài đặt.
class ConnectionTest {
  const ConnectionTest({
    this.error,
    this.hardwareOnline,
    this.rpm,
    this.temperature,
  });
  final BlynkErrorKind? error;
  final bool? hardwareOnline;
  final double? rpm;
  final double? temperature;
}

/// Lớp mỏng gọi Blynk HTTPS API. Không có logic polling ở đây.
class BlynkApi {
  BlynkApi({
    required String host,
    required String token,
    Dio? dio,
    Duration timeout = const Duration(seconds: 5),
  }) : _host = normalizeHost(host),
       _token = token.trim(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: timeout,
               receiveTimeout: timeout,
               sendTimeout: timeout,
               responseType: ResponseType.plain,
               // Tự xử lý mã trạng thái để map ra BlynkErrorKind.
               validateStatus: (_) => true,
             ),
           );

  final String _host;
  final String _token;
  final Dio _dio;

  Uri _uri(String path, String query) => Uri(
    scheme: 'https',
    host: _host,
    path: '/external/api/$path',
    query: 'token=${Uri.encodeQueryComponent(_token)}$query',
  );

  /// `GET /external/api/get?token=...&v0&v1...` -> nội dung phản hồi thô.
  Future<String> getRaw(List<int> pins) =>
      _request(_uri('get', pins.map((p) => '&v$p').join()));

  /// `GET /external/api/update?token=...&v0=1&v2=0` (nhiều pin trong một lệnh).
  Future<void> update(Map<int, String> values) async {
    final q = values.entries
        .map((e) => '&v${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join();
    await _request(_uri('update', q));
  }

  /// `GET /external/api/isHardwareConnected?token=...`
  Future<bool> isHardwareConnected() async {
    final body = (await _request(
      _uri('isHardwareConnected', ''),
    )).trim().toLowerCase();
    if (body.contains('true')) return true;
    if (body.contains('false')) return false;
    throw const BlynkException(BlynkErrorKind.badResponse);
  }

  Future<String> _request(Uri uri) async {
    final Response<String> res;
    try {
      res = await _dio.getUri<String>(uri);
    } on DioException catch (e) {
      final timeout =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      throw BlynkException(
        timeout ? BlynkErrorKind.timeout : BlynkErrorKind.network,
      );
    }
    final code = res.statusCode ?? 0;
    final body = res.data ?? '';
    if (code >= 200 && code < 300) return body;
    // Hết hạn mức tin nhắn của gói Blynk ("Messages limit reached!"): không phải
    // lỗi token hay pin, và sẽ tự hết khi hạn mức được làm mới.
    if (body.toLowerCase().contains('limit')) {
      throw BlynkException(BlynkErrorKind.rateLimited, code);
    }
    if (code == 401 || code == 403) {
      throw BlynkException(BlynkErrorKind.invalidToken, code);
    }
    if (code == 429) throw BlynkException(BlynkErrorKind.rateLimited, code);
    if (code >= 500) throw BlynkException(BlynkErrorKind.server, code);
    if (code == 400) {
      // Cả token sai lẫn pin sai đều có thể là 400: phân biệt qua nội dung lỗi.
      final lower = body.toLowerCase();
      throw BlynkException(
        lower.contains('token')
            ? BlynkErrorKind.invalidToken
            : BlynkErrorKind.invalidPin,
        code,
      );
    }
    throw BlynkException(BlynkErrorKind.badResponse, code);
  }

  /// Thử kết nối: kiểm tra token, thiết bị online, và đọc thử tốc độ/nhiệt độ.
  Future<ConnectionTest> test(PinMap pins) async {
    final bool online;
    try {
      online = await isHardwareConnected();
    } on BlynkException catch (e) {
      return ConnectionTest(error: e.kind);
    }
    if (pins.missingRequired.isNotEmpty) {
      return ConnectionTest(hardwareOnline: online);
    }
    try {
      final values = parseGetResponse(
        await getRaw(pins.readPins),
        pins.readPins,
      );
      final TelemetryData? t = buildTelemetry(values, pins, DateTime.now());
      return ConnectionTest(
        hardwareOnline: online,
        rpm: t?.rpm,
        temperature: t?.temperature,
      );
    } on BlynkException catch (e) {
      return ConnectionTest(error: e.kind, hardwareOnline: online);
    } on BlynkParseException {
      return ConnectionTest(
        error: BlynkErrorKind.badResponse,
        hardwareOnline: online,
      );
    }
  }

  void close() => _dio.close();
}
