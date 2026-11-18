import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/warning_evaluator.dart';
import '../status_labels.dart';
import 'arc_gauge.dart';

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.title,
    required this.gauge,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final Widget gauge;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            gauge,
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gauge "Tốc độ" - chỉ rebuild khi rpm / ngưỡng / kết nối thay đổi.
class SpeedGaugeCard extends ConsumerWidget {
  const SpeedGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rpm = ref.watch(latestTelemetryProvider.select((t) => t?.rpm));
    final t = ref.watch(thresholdsProvider);
    final connected = ref.watch(isConnectedProvider);
    final p = context.palette;
    final track = Theme.of(context).colorScheme.outlineVariant;

    if (rpm == null) {
      return _GaugeCard(
        title: 'Tốc độ',
        gauge: ArcGauge(
          fraction: 0,
          color: p.muted,
          trackColor: track,
          valueText: '--',
          unit: 'vòng/phút',
        ),
        status: 'Đang chờ dữ liệu…',
        statusColor: p.muted,
      );
    }

    final status = WarningEvaluator.speed(rpm, t);
    final active = connected;
    final arcColor = !active
        ? p.muted
        : status == SpeedStatus.stable
        ? p.speed
        : p.forLevel(status.level);
    final statusColor = !active || status == SpeedStatus.stopped
        ? p.muted
        : p.forLevel(status.level);

    return _GaugeCard(
      title: 'Tốc độ',
      gauge: ArcGauge(
        fraction: rpm / t.rpmMax,
        color: arcColor,
        trackColor: track,
        valueText: rpm.round().toString(),
        unit: 'vòng/phút',
      ),
      status: status.label,
      statusColor: statusColor,
    );
  }
}

/// Gauge "Nhiệt độ" - đổi màu theo ngưỡng.
class TemperatureGaugeCard extends ConsumerWidget {
  const TemperatureGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temp = ref.watch(
      latestTelemetryProvider.select((t) => t?.temperature),
    );
    final t = ref.watch(thresholdsProvider);
    final connected = ref.watch(isConnectedProvider);
    final p = context.palette;
    final track = Theme.of(context).colorScheme.outlineVariant;

    if (temp == null) {
      return _GaugeCard(
        title: 'Nhiệt độ',
        gauge: ArcGauge(
          fraction: 0,
          color: p.muted,
          trackColor: track,
          valueText: '--',
          unit: '°C',
        ),
        status: 'Đang chờ dữ liệu…',
        statusColor: p.muted,
      );
    }

    final status = WarningEvaluator.temperature(temp, t);
    final arcColor = !connected
        ? p.muted
        : status == TempStatus.normal
        ? p.temperature
        : p.forLevel(status.level);

    return _GaugeCard(
      title: 'Nhiệt độ',
      gauge: ArcGauge(
        fraction: temp / t.tempMax,
        color: arcColor,
        trackColor: track,
        valueText: temp.round().toString(),
        unit: '°C',
      ),
      status: status.label,
      statusColor: connected ? p.forLevel(status.level) : p.muted,
    );
  }
}
