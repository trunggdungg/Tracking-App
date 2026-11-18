/// Vấn đề mà UI cần báo rõ cho người dùng và dẫn tới màn hình Cài đặt.
enum DeviceIssue {
  none,

  /// Chưa nhập token hoặc chưa điền pin bắt buộc (tốc độ, nhiệt độ).
  notConfigured,

  /// Máy chủ báo token sai / đã bị thu hồi.
  invalidToken,

  /// Máy chủ báo pin không tồn tại: ánh xạ pin có thể sai.
  invalidPins,
}
