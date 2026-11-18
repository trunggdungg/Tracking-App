import '../../data/blynk/blynk_api.dart';
import '../../domain/device_issue.dart';

extension BlynkErrorMessage on BlynkErrorKind {
  String get message => switch (this) {
    BlynkErrorKind.invalidToken => 'Token không hợp lệ hoặc đã bị thu hồi.',
    BlynkErrorKind.invalidPin =>
      'Pin không tồn tại trên thiết bị. Kiểm tra lại ánh xạ pin.',
    BlynkErrorKind.rateLimited =>
      'Blynk báo đã hết hạn mức tin nhắn. Dữ liệu sẽ có lại khi hạn mức làm mới.',
    BlynkErrorKind.server => 'Máy chủ Blynk đang lỗi, hãy thử lại sau.',
    BlynkErrorKind.timeout => 'Hết thời gian chờ phản hồi.',
    BlynkErrorKind.network =>
      'Không kết nối được. Kiểm tra mạng và tên máy chủ (host).',
    BlynkErrorKind.badResponse => 'Phản hồi từ máy chủ không đọc được.',
  };
}

extension DeviceIssueMessage on DeviceIssue {
  String? get message => switch (this) {
    DeviceIssue.none => null,
    DeviceIssue.notConfigured =>
      'Chưa cấu hình kết nối: cần token và pin tốc độ, nhiệt độ.',
    DeviceIssue.invalidToken => 'Token không hợp lệ hoặc đã bị thu hồi.',
    DeviceIssue.invalidPins =>
      'Blynk báo pin không tồn tại. Kiểm tra lại ánh xạ pin.',
    DeviceIssue.quotaExceeded =>
      'Blynk đã hết hạn mức tin nhắn nên tạm không gửi/nhận được dữ liệu. '
          'Hãy chờ hạn mức làm mới hoặc nâng cấp gói.',
  };
}
