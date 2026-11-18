import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/utils/downsample.dart';
import '../../domain/telemetry_data.dart';

enum ChartRange {
  live('Trực tiếp', null),
  hour('1 giờ', Duration(hours: 1)),
  day('1 ngày', Duration(days: 1)),
  week('7 ngày', Duration(days: 7));

  const ChartRange(this.label, this.span);
  final String label;

  /// null = cửa sổ trượt trực tiếp.
  final Duration? span;
}

class ChartRangeNotifier extends Notifier<ChartRange> {
  @override
  ChartRange build() => ChartRange.live;

  void select(ChartRange range) => state = range;
}

final chartRangeProvider = NotifierProvider<ChartRangeNotifier, ChartRange>(
  ChartRangeNotifier.new,
);

/// Dữ liệu cho các khoảng 1 giờ / 1 ngày / 7 ngày: đọc từ repository
/// (SQLite ở bước 2) rồi tự giảm mẫu nếu quá nhiều điểm.
final rangeHistoryProvider = FutureProvider.autoDispose
    .family<List<TelemetryData>, ChartRange>((ref, range) async {
      final span = range.span!;
      final now = DateTime.now();
      final data = await ref
          .read(deviceRepositoryProvider)
          .history(now.subtract(span), now);
      return downsample(data, kMaxChartPoints);
    });
