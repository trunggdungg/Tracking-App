import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/theme.dart';
import '../../domain/telemetry_data.dart';

/// Biểu đồ đường 2 chuỗi (tốc độ, nhiệt độ), dùng cho cả màn Trực tiếp và Lịch sử.
///
/// Hai đại lượng khác thang đo nên vẽ theo tỉ lệ (rpm / rpmMax, nhiệt độ / tempMax);
/// chạm vào biểu đồ để xem giá trị thật.
class TelemetryLineChart extends ConsumerWidget {
  const TelemetryLineChart({
    super.key,
    required this.data,
    this.zoomable = false,
    this.showTimeAxis = false,
    this.showDate = false,
  });

  final List<TelemetryData> data;

  /// Cho phép chụm 2 ngón để zoom và kéo ngang (màn Lịch sử).
  final bool zoomable;

  /// Hiện nhãn thời gian dưới trục X.
  final bool showTimeAxis;

  /// Nhãn/tooltip có kèm ngày (khoảng thời gian dài).
  final bool showDate;

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

    final first = data.first.timestamp;
    final t0 = first.millisecondsSinceEpoch;
    double x(TelemetryData d) =>
        (d.timestamp.millisecondsSinceEpoch - t0) / 1000.0;
    final maxX = x(data.last);

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

    final tooltipFmt = DateFormat(showDate ? 'dd/MM HH:mm:ss' : 'HH:mm:ss');
    final axisFmt = DateFormat(
      maxX > 86400
          ? 'dd/MM HH:mm'
          : maxX > 600
          ? 'HH:mm'
          : 'HH:mm:ss',
    );

    return LineChart(
      duration: Duration.zero, // cập nhật liên tục: bỏ animation cho nhẹ
      transformationConfig: zoomable
          ? const FlTransformationConfig(
              scaleAxis: FlScaleAxis.horizontal,
              minScale: 1,
              maxScale: 30,
            )
          : const FlTransformationConfig(),
      LineChartData(
        minY: 0,
        maxY: 1,
        minX: 0,
        maxX: maxX,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showTimeAxis,
              reservedSize: 24,
              getTitlesWidget: (value, meta) => value == meta.max
                  // Bỏ nhãn ở mép phải: nó hay đè lên nhãn liền trước.
                  ? const SizedBox.shrink()
                  : SideTitleWidget(
                      meta: meta,
                      child: Text(
                        axisFmt.format(
                          first.add(
                            Duration(milliseconds: (value * 1000).round()),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
        ),
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
                          '${tooltipFmt.format(d.timestamp)}\n'
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
