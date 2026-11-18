import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/history_recorder.dart';
import '../../app/providers.dart';
import '../../core/theme.dart';
import '../common/telemetry_line_chart.dart';
import 'alert_labels.dart';
import 'history_providers.dart';

final _dateTimeFmt = DateFormat('dd/MM HH:mm');
final _dateTimeSecFmt = DateFormat('dd/MM HH:mm:ss');

/// Màn hình Lịch sử: chọn khoảng thời gian, biểu đồ zoom/kéo,
/// danh sách sự kiện cảnh báo, xóa dữ liệu cũ.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(historyDataProvider);
        await ref.read(historyDataProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          _RangeCard(),
          SizedBox(height: 12),
          _ChartCard(),
          SizedBox(height: 12),
          _AlertsCard(),
          SizedBox(height: 12),
          _RetentionNote(),
        ],
      ),
    );
  }
}

class _RangeCard extends ConsumerWidget {
  const _RangeCard();

  /// Khoảng tùy chọn: chọn ngày bắt đầu/kết thúc rồi giờ bắt đầu/kết thúc.
  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final days = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 1)),
        end: now,
      ),
      helpText: 'Chọn khoảng ngày',
      saveText: 'Tiếp',
    );
    if (days == null || !context.mounted) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      helpText: 'Giờ bắt đầu',
    );
    if (startTime == null || !context.mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: DateUtils.isSameDay(days.end, now)
          ? TimeOfDay.fromDateTime(now)
          : const TimeOfDay(hour: 23, minute: 59),
      helpText: 'Giờ kết thúc',
    );
    if (endTime == null || !context.mounted) return;

    final from = combine(days.start, startTime);
    final to = combine(days.end, endTime);
    if (!to.isAfter(from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời điểm kết thúc phải sau thời điểm bắt đầu.'),
        ),
      );
      return;
    }
    ref.read(historySelectionProvider.notifier).setCustom(from, to);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(historySelectionProvider);
    final result = ref.watch(historyDataProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Khoảng thời gian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(historyDataProvider),
                ),
                const _DeleteMenu(),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final p in HistoryPreset.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: p == selection.preset,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.transparent,
                    selectedColor: scheme.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: p == selection.preset
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    onSelected: (_) {
                      if (p == HistoryPreset.custom) {
                        _pickCustom(context, ref);
                      } else {
                        ref.read(historySelectionProvider.notifier).select(p);
                      }
                    },
                  ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              Text(
                '${_dateTimeFmt.format(result.from)}  →  ${_dateTimeFmt.format(result.to)}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Menu xóa lịch sử cũ - luôn hỏi xác nhận trước khi xóa.
class _DeleteMenu extends ConsumerWidget {
  const _DeleteMenu();

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref, {
    required String question,
    required Future<int> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử?'),
        content: Text('$question\nThao tác này không thể hoàn tác.'),
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await action();
      ref.invalidate(historyDataProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xóa $n dòng dữ liệu.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Xóa thất bại, hãy thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<int> olderThan(Duration d) =>
        ref.read(historyStoreProvider).deleteBefore(DateTime.now().subtract(d));

    return PopupMenuButton<int>(
      tooltip: 'Xóa lịch sử',
      icon: const Icon(Icons.delete_outline),
      onSelected: (i) {
        switch (i) {
          case 0:
            _confirmAndDelete(
              context,
              ref,
              question: 'Xóa dữ liệu cũ hơn 7 ngày?',
              action: () => olderThan(const Duration(days: 7)),
            );
          case 1:
            _confirmAndDelete(
              context,
              ref,
              question: 'Xóa dữ liệu cũ hơn 1 ngày?',
              action: () => olderThan(const Duration(days: 1)),
            );
          case 2:
            _confirmAndDelete(
              context,
              ref,
              question: 'Xóa toàn bộ lịch sử và danh sách cảnh báo?',
              action: () async {
                await ref.read(historyStoreProvider).deleteAll();
                return 0;
              },
            );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 0, child: Text('Xóa dữ liệu cũ hơn 7 ngày')),
        PopupMenuItem(value: 1, child: Text('Xóa dữ liệu cũ hơn 1 ngày')),
        PopupMenuItem(value: 2, child: Text('Xóa toàn bộ lịch sử')),
      ],
    );
  }
}

class _ChartCard extends ConsumerWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyDataProvider);
    final scheme = Theme.of(context).colorScheme;
    final p = context.palette;

    Widget body = async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không đọc được lịch sử.'),
            TextButton(
              onPressed: () => ref.invalidate(historyDataProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (r) {
        if (r.data.isEmpty) {
          return Center(
            child: Text(
              'Không có dữ liệu trong khoảng này',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return TelemetryLineChart(
          data: r.data,
          zoomable: true,
          showTimeAxis: true,
          showDate: r.to.difference(r.from) > const Duration(hours: 24),
        );
      },
    );

    final count = async.value?.data.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Biểu đồ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (count != null)
                  Text(
                    '$count điểm',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: body),
            const SizedBox(height: 8),
            Row(
              children: [
                _dot(p.speed, 'Tốc độ', scheme),
                const SizedBox(width: 16),
                _dot(p.temperature, 'Nhiệt độ', scheme),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Chụm hai ngón để zoom, kéo ngang để di chuyển, chạm để xem giá trị.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, String label, ColorScheme scheme) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
    ],
  );
}

class _AlertsCard extends ConsumerWidget {
  const _AlertsCard();

  static const _maxShown = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(
      historyDataProvider.select((a) => a.value?.alerts),
    );
    final scheme = Theme.of(context).colorScheme;
    final p = context.palette;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alerts == null
                  ? 'Sự kiện cảnh báo'
                  : 'Sự kiện cảnh báo (${alerts.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (alerts == null)
              const SizedBox.shrink()
            else if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Không có cảnh báo nào trong khoảng này.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else ...[
              for (final e in alerts.take(_maxShown))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.circle,
                    size: 14,
                    color: p.forLevel(e.level),
                  ),
                  title: Text(e.type.label),
                  subtitle: Text(_dateTimeSecFmt.format(e.timestamp)),
                  trailing: Text(
                    alertValueText(e),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (alerts.length > _maxShown)
                Text(
                  'Chỉ hiển thị $_maxShown sự kiện mới nhất.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RetentionNote extends ConsumerWidget {
  const _RetentionNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(retentionDaysProvider);
    return Text(
      'Dữ liệu cũ hơn $days ngày được tự động xóa.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
