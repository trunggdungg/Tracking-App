import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../features/history/history_screen.dart';
import '../features/live/live_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/history/history_providers.dart';
import 'history_recorder.dart';
import 'providers.dart';

/// Khung ứng dụng: thanh trên (tiêu đề + trạng thái kết nối),
/// banner mất kết nối, nội dung 3 tab và thanh điều hướng dưới.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Bật bộ ghi lịch sử chạy ngầm suốt vòng đời app.
    ref.read(historyRecorderProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Giữ bộ đệm biểu đồ luôn chạy kể cả khi đang ở tab khác
    // (listen không làm shell rebuild).
    ref.listen(liveBufferProvider, (_, _) {});

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const Divider(),
            const _DisconnectedBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  LiveScreen(),
                  HistoryScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            // Vào tab Lịch sử thì tải lại để thấy dữ liệu mới nhất.
            if (i == 1) ref.invalidate(historyDataProvider);
            setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              label: 'Trực tiếp',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giám sát động cơ',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const _LastUpdateText(),
              ],
            ),
          ),
          const _ConnectionChip(),
        ],
      ),
    );
  }
}

/// "Cập nhật X giây trước" - tự đếm mỗi giây, chỉ widget này rebuild.
class _LastUpdateText extends ConsumerWidget {
  const _LastUpdateText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = ref.watch(latestTelemetryProvider.select((t) => t?.timestamp));
    ref.watch(secondTickerProvider); // kích rebuild mỗi giây
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    if (ts == null) return Text('Đang chờ dữ liệu…', style: style);
    final secs = DateTime.now().difference(ts).inSeconds.clamp(0, 1 << 30);
    final label = secs < 60
        ? '$secs giây trước'
        : secs < 3600
        ? '${secs ~/ 60} phút trước'
        : '${secs ~/ 3600} giờ trước';
    return Text('Cập nhật $label', style: style);
  }
}

class _ConnectionChip extends ConsumerWidget {
  const _ConnectionChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionStateProvider);
    final p = context.palette;
    final (color, icon, label) = switch (state) {
      true => (p.ok, Icons.wifi, 'Đã kết nối'),
      false => (p.danger, Icons.wifi_off, 'Ngắt kết nối'),
      null => (p.muted, Icons.sync, 'Đang kết nối'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DisconnectedBanner extends ConsumerWidget {
  const _DisconnectedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(connectionStateProvider) == false;
    if (!offline) return const SizedBox.shrink();
    final danger = context.palette.danger;
    return Container(
      width: double.infinity,
      color: danger.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mất kết nối với thiết bị. Các nút điều khiển đã bị khóa.',
              style: TextStyle(color: danger),
            ),
          ),
        ],
      ),
    );
  }
}
