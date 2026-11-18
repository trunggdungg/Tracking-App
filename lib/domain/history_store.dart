import 'alert_event.dart';
import 'telemetry_data.dart';

/// Nơi lưu lịch sử cục bộ (SQLite ở bản thật, bộ nhớ khi test).
abstract class HistoryStore {
  Future<void> insertTelemetry(List<TelemetryData> rows);

  /// Mẫu đo trong [from, to], tăng dần theo thời gian.
  /// [maxPoints] != null và có nhiều điểm hơn: trả về bản đã giảm mẫu.
  Future<List<TelemetryData>> telemetryBetween(
    DateTime from,
    DateTime to, {
    int? maxPoints,
  });

  Future<void> insertAlert(AlertEvent event);

  /// Sự kiện cảnh báo trong [from, to], MỚI NHẤT TRƯỚC.
  Future<List<AlertEvent>> alertsBetween(DateTime from, DateTime to);

  /// Xóa mọi dữ liệu (cả mẫu đo lẫn cảnh báo) cũ hơn [cutoff]. Trả về số dòng đã xóa.
  Future<int> deleteBefore(DateTime cutoff);

  Future<void> deleteAll();

  Future<void> close();
}
