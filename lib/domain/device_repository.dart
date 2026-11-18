import 'device_command.dart';
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

  /// Gửi lệnh; trả về true nếu thiết bị/cloud xác nhận thành công.
  Future<bool> sendCommand(DeviceCommand cmd);

  /// Lịch sử mẫu đo trong khoảng [from, to], sắp xếp tăng dần theo thời gian.
  Future<List<TelemetryData>> history(DateTime from, DateTime to);

  /// Giải phóng timer/stream. (Bổ sung so với interface gốc để tránh rò rỉ.)
  Future<void> dispose();
}
