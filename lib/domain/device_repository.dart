import 'device_command.dart';
import 'device_issue.dart';
import 'telemetry_data.dart';

/// Giao diện duy nhất mà UI được phép dùng để nói chuyện với thiết bị.
///
/// Các bản cài đặt: `MockRepository`, `BlynkRepository` (bước 3),
/// và sau này `MqttRepository` - chỉ cần thêm lớp mới, không sửa UI.
abstract class DeviceRepository {
  /// Luồng mẫu đo mới nhất.
  Stream<TelemetryData> telemetryStream();

  /// Luồng trạng thái kết nối tới thiết bị (true = đang online).
  Stream<bool> connectionStream();

  /// Vấn đề cấu hình/xác thực đang xảy ra (token sai, chưa cấu hình...).
  /// `DeviceIssue.none` khi mọi thứ bình thường.
  Stream<DeviceIssue> issueStream();

  /// Tạm dừng / chạy lại việc lấy dữ liệu (app vào nền / quay về).
  void pause();
  void resume();

  /// Gửi lệnh; trả về true nếu thiết bị/cloud xác nhận thành công.
  Future<bool> sendCommand(DeviceCommand cmd);

  /// Lịch sử mẫu đo trong khoảng [from, to], sắp xếp tăng dần theo thời gian.
  /// [maxPoints]: nếu có, giảm mẫu về tối đa ngần ấy điểm (để vẽ biểu đồ);
  /// để null khi cần dữ liệu thô (ví dụ xuất CSV).
  Future<List<TelemetryData>> history(
    DateTime from,
    DateTime to, {
    int? maxPoints,
  });

  /// Giải phóng timer/stream. (Bổ sung so với interface gốc để tránh rò rỉ.)
  Future<void> dispose();
}
