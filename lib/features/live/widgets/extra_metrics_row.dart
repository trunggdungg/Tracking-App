import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme.dart';

/// Hàng thẻ nhỏ: rung / dòng điện / sức khỏe / lỗi. Trường null thì ẩn.
class ExtraMetricsRow extends ConsumerWidget {
  const ExtraMetricsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (vibration, current, health, fault) = ref.watch(
      latestTelemetryProvider.select(
        (t) => (t?.vibration, t?.current, t?.healthPercent, t?.fault),
      ),
    );

    final items = <_Metric>[
      if (vibration != null)
        _Metric('Rung', vibration.toStringAsFixed(1), 'mm/s'),
      if (current != null)
        _Metric('Dòng điện', current.toStringAsFixed(1), 'A'),
      if (health != null) _Metric('Sức khỏe', health.round().toString(), '%'),
      if (fault != null)
        _Metric('Lỗi', fault, '', color: context.palette.danger),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final m in items) _MetricCard(m)],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.unit, {this.color});
  final String label;
  final String value;
  final String unit;
  final Color? color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: metric.value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: metric.color,
                      ),
                    ),
                    if (metric.unit.isNotEmpty)
                      TextSpan(
                        text: ' ${metric.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
