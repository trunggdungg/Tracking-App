import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Thẻ công tắc "Động cơ". Chỉ đổi trạng thái sau khi lệnh gửi thành công.
class MotorSwitchCard extends ConsumerWidget {
  const MotorSwitchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(motorControllerProvider);
    final connected = ref.watch(isConnectedProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Động cơ', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: state.enabled,
                  onChanged: connected && !state.busy
                      ? (v) async {
                          final ok = await ref
                              .read(motorControllerProvider.notifier)
                              .setEnabled(v);
                          if (!ok && context.mounted) {
                            _snack(
                              context,
                              'Gửi lệnh thất bại, trạng thái được giữ nguyên.',
                            );
                          }
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                if (state.busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    state.enabled ? 'Bật' : 'Tắt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ nút đỏ "Dừng động cơ" - có hộp thoại xác nhận trước khi gửi.
class EmergencyStopCard extends ConsumerWidget {
  const EmergencyStopCard({super.key});

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dừng khẩn cấp?'),
        content: const Text('Động cơ sẽ bị dừng ngay lập tức.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dừng động cơ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(motorControllerProvider.notifier).emergencyStop();
    if (context.mounted) {
      _snack(
        context,
        ok
            ? 'Đã gửi lệnh dừng động cơ.'
            : 'Gửi lệnh dừng thất bại, hãy thử lại!',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (busy, running) = ref.watch(
      motorControllerProvider.select((s) => (s.busy, s.enabled)),
    );
    final connected = ref.watch(isConnectedProvider);
    final scheme = Theme.of(context).colorScheme;
    // Động cơ đã dừng thì không còn gì để dừng: khóa nút.
    final canStop = connected && !busy && running;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dừng khẩn cấp',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                ),
                onPressed: canStop ? () => _onPressed(context, ref) : null,
                icon: Icon(
                  running
                      ? Icons.stop_circle_outlined
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  running ? 'Dừng động cơ' : 'Đã dừng',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
