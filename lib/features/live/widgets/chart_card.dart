import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../common/telemetry_line_chart.dart';
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
