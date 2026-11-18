import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../domain/alert_event.dart';
import '../../domain/telemetry_data.dart';

enum HistoryPreset {
  hour('1 giờ'),
  today('Hôm nay'),
  week('7 ngày'),
  custom('Tùy chọn');

  const HistoryPreset(this.label);
  final String label;
}

/// Khoảng thời gian người dùng chọn. Với 3 mốc nhanh, [from]/[to] được tính
/// lại từ "bây giờ" mỗi lần tải; chỉ khoảng tùy chọn mới cố định.
class HistorySelection {
  const HistorySelection(this.preset, {this.customFrom, this.customTo});
  final HistoryPreset preset;
  final DateTime? customFrom;
  final DateTime? customTo;
}

({DateTime from, DateTime to}) resolveRange(HistorySelection s, DateTime now) {
  switch (s.preset) {
    case HistoryPreset.hour:
      return (from: now.subtract(const Duration(hours: 1)), to: now);
    case HistoryPreset.today:
      return (from: DateTime(now.year, now.month, now.day), to: now);
    case HistoryPreset.week:
      return (from: now.subtract(const Duration(days: 7)), to: now);
    case HistoryPreset.custom:
      return (from: s.customFrom ?? now, to: s.customTo ?? now);
  }
}

class HistorySelectionNotifier extends Notifier<HistorySelection> {
  @override
  HistorySelection build() => const HistorySelection(HistoryPreset.hour);

  void select(HistoryPreset preset) => state = HistorySelection(preset);

  void setCustom(DateTime from, DateTime to) => state = HistorySelection(
    HistoryPreset.custom,
    customFrom: from,
    customTo: to,
  );
}

final historySelectionProvider =
    NotifierProvider<HistorySelectionNotifier, HistorySelection>(
      HistorySelectionNotifier.new,
    );

class HistoryResult {
  const HistoryResult({
    required this.from,
    required this.to,
    required this.data,
    required this.alerts,
  });
  final DateTime from;
  final DateTime to;

  /// Đã giảm mẫu để vẽ biểu đồ.
  final List<TelemetryData> data;

  /// Mới nhất trước.
  final List<AlertEvent> alerts;
}

/// Dữ liệu của màn Lịch sử cho khoảng đang chọn. Tải lại bằng
/// `ref.invalidate(historyDataProvider)` (kéo xuống, đổi tab, sau khi xóa).
final historyDataProvider = FutureProvider.autoDispose<HistoryResult>((
  ref,
) async {
  final selection = ref.watch(historySelectionProvider);
  final range = resolveRange(selection, DateTime.now());
  final data = await ref
      .read(deviceRepositoryProvider)
      .history(range.from, range.to, maxPoints: kMaxChartPoints);
  final alerts = await ref
      .read(historyStoreProvider)
      .alertsBetween(range.from, range.to);
  return HistoryResult(
    from: range.from,
    to: range.to,
    data: data,
    alerts: alerts,
  );
});

/// Ghép ngày (từ date picker) với giờ (từ time picker).
DateTime combine(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
