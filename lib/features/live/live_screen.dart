import 'package:flutter/material.dart';

import 'widgets/alert_lamp_card.dart';
import 'widgets/chart_card.dart';
import 'widgets/control_row.dart';
import 'widgets/extra_metrics_row.dart';
import 'widgets/gauge_row.dart';

/// Màn hình Trực tiếp. Mỗi thẻ tự theo dõi đúng dữ liệu nó cần
/// nên màn hình này không rebuild khi có mẫu đo mới.
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  Widget _row(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(const MotorSwitchCard(), const EmergencyStopCard()),
        const SizedBox(height: 12),
        _row(const SpeedGaugeCard(), const TemperatureGaugeCard()),
        const SizedBox(height: 12),
        const AlertLampCard(),
        const SizedBox(height: 12),
        const ChartCard(),
        const SizedBox(height: 12),
        const ExtraMetricsRow(),
      ],
    );
  }
}
