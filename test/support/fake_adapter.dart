import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Phản hồi giả: mã trạng thái + nội dung, hoặc ném lỗi mạng.
class FakeReply {
  const FakeReply(this.status, this.body);
  const FakeReply.network() : status = -1, body = '';
  final int status;
  final String body;
  bool get isNetworkError => status == -1;
}

/// HttpClientAdapter giả cho dio: ghi lại mọi URL được gọi và trả lời bằng [handler].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeReply Function(Uri uri) handler;
  final requests = <Uri>[];

  /// Các lần gọi theo tên endpoint (get / update / isHardwareConnected).
  List<Uri> calls(String endpoint) =>
      requests.where((u) => u.path.endsWith('/$endpoint')).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    final reply = handler(options.uri);
    if (reply.isNetworkError) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'giả lập mất mạng',
      );
    }
    return ResponseBody.fromString(
      reply.body,
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['text/plain'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeAdapter adapter) => Dio(
  BaseOptions(responseType: ResponseType.plain, validateStatus: (_) => true),
)..httpClientAdapter = adapter;
