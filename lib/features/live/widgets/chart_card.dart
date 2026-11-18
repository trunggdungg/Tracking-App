import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/telemetry_data.dart';
import '../live_providers.dart';

/// Thẻ "Biểu đồ": hai chuỗi (tốc độ, nhiệt độ) + chip chọn khoảng thời gian.
class ChartCard extends ConsumerWidget {
  const ChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(chartRangeProvider);
    final scheme = Theme.of(context).colorScheme;
    final p = context.palette;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap: màn hình hẹp thì chip tự xuống dòng thay vì bị cắt.
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Biểu đồ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final r in ChartRange.values)
                  ChoiceChip(
                    label: Text(r.label),
                    selected: r == range,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.transparent,
                    selectedColor: scheme.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: r == range
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    onSelected: (_) =>
                        ref.read(chartRangeProvider.notifier).select(r),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 130, child: _ChartBody(range: range)),
            const SizedBox(height: 12),
            Row(
              children: [
                _Legend(color: p.speed, label: 'Tốc độ'),
                const SizedBox(width: 16),
                _Legend(color: p.temperature, label: 'Nhiệt độ'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartBody extends ConsumerWidget {
  const _ChartBody({required this.range});
  final ChartRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (range == ChartRange.live) {
      return TelemetryLineChart(data: ref.watch(liveBufferProvider));
    }
    return ref
        .watch(rangeHistoryProvider(range))
        .when(
          data: (d) => TelemetryLineChart(data: d),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Không đọc được lịch sử.')),
        );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

/// Biểu đồ đường 2 chuỗi. Hai đại lượng khác thang đo nên vẽ theo tỉ lệ
/// (rpm / rpmMax, nhiệt độ / tempMax); chạm vào để xem giá trị thật.
class TelemetryLineChart extends ConsumerWidget {
  const TelemetryLineChart({super.key, required this.data});
  final List<TelemetryData> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.palette;
    final t = ref.watch(thresholdsProvider);

    if (data.length < 2) {
      return Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final t0 = data.first.timestamp.millisecondsSinceEpoch;
    double x(TelemetryData d) =>
        (d.timestamp.millisecondsSinceEpoch - t0) / 1000.0;

    final rpmSpots = [
      for (final d in data) FlSpot(x(d), (d.rpm / t.rpmMax).clamp(0, 1)),
    ];
    final tempSpots = [
      for (final d in data)
        FlSpot(x(d), (d.temperature / t.tempMax).clamp(0, 1)),
    ];

    LineChartBarData bar(List<FlSpot> spots, Color color) => LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 2,
      isCurved: false,
      dotData: const FlDotData(show: false),
    );

    final timeFmt = DateFormat('HH:mm:ss');

    return LineChart(
      duration: Duration.zero, // cập nhật mỗi giây: bỏ animation cho nhẹ
      LineChartData(
        minY: 0,
        maxY: 1,
        minX: 0,
        maxX: x(data.last),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outline.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        lineBarsData: [bar(rpmSpots, p.speed), bar(tempSpots, p.temperature)],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.surfaceContainerHighest,
            getTooltipItems: (spots) {
              if (spots.isEmpty) return const [];
              final d = data[spots.first.spotIndex];
              final style = TextStyle(color: scheme.onSurface, fontSize: 12);
              // Chỉ điểm đầu tiên mang nội dung, các điểm còn lại để null.
              return [
                for (var i = 0; i < spots.length; i++)
                  i == 0
                      ? LineTooltipItem(
                          '${timeFmt.format(d.timestamp)}\n'
                          'Tốc độ: ${d.rpm.round()} vòng/phút\n'
                          'Nhiệt độ: ${d.temperature.toStringAsFixed(1)} °C',
                          style,
                        )
                      : null,
              ];
            },
          ),
        ),
      ),
    );
  }
}
