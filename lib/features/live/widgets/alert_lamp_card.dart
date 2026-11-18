import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/telemetry_data.dart';
import '../status_labels.dart';

/// Thẻ "Đèn cảnh báo": đèn tròn xanh/vàng/đỏ, mô tả, biểu tượng còi.
class AlertLampCard extends ConsumerWidget {
  const AlertLampCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (level, buzzerOn) = ref.watch(
      latestTelemetryProvider.select((t) => (t?.warningLevel, t?.buzzerOn)),
    );
    final connected = ref.watch(isConnectedProvider);
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;

    final color = level == null || !connected ? p.muted : p.forLevel(level);
    final title = level == null
        ? 'Đèn cảnh báo: chưa có dữ liệu'
        : 'Đèn cảnh báo: ${level.label}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chuyển đỏ khi quá nhiệt hoặc rung mạnh',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  // Chỉ hiện nút khi còi đang kêu (thiết bị hỗ trợ tắt còi).
                  if (buzzerOn == true && connected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await ref
                              .read(motorControllerProvider.notifier)
                              .muteBuzzer();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không tắt được còi, thử lại.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.volume_off, size: 18),
                        label: const Text('Tắt còi'),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              buzzerOn == true
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: buzzerOn == true && level == WarningLevel.danger
                  ? p.danger
                  : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
