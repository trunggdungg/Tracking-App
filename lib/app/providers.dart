import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/local/app_database.dart';
import '../data/local/drift_history_store.dart';
import '../data/blynk/blynk_config.dart';
import '../data/repositories/blynk_repository.dart';
import '../data/repositories/mock_repository.dart';
import '../domain/device_command.dart';
import '../domain/device_issue.dart';
import '../domain/device_repository.dart';
import '../domain/history_store.dart';
import '../domain/telemetry_data.dart';
import '../domain/warning_evaluator.dart';
import 'settings_providers.dart';

// Các provider cài đặt cũng được truy cập qua file này cho gọn.
export 'settings_providers.dart';

/// Kho lịch sử cục bộ (SQLite). Test/preview có thể override bằng MemoryHistoryStore.
final historyStoreProvider = Provider<HistoryStore>((ref) {
  final store = DriftHistoryStore(AppDatabase());
  ref.onDispose(store.close);
  return store;
});

/// ĐIỂM CHUYỂN REPOSITORY DUY NHẤT của app.
/// Thêm MqttRepository sau này chỉ cần thêm một nhánh ở đây, không sửa UI.
///
/// Đổi nguồn dữ liệu, host, chu kỳ hay ánh xạ pin trong Cài đặt thì repository
/// được dựng lại (cái cũ tự dispose). Đổi ngưỡng/số ngày lưu thì KHÔNG dựng lại.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final (useMock, host, pollSeconds, pinMap) = ref.watch(
    settingsProvider.select(
      (s) => (s.useMock, s.host, s.pollSeconds, s.pinMap),
    ),
  );
  final store = ref.watch(historyStoreProvider);

  final DeviceRepository repo = useMock
      ? MockRepository(store: store)
      : BlynkRepository(
          config: BlynkConfig(
            host: normalizeHost(host),
            // Chỉ theo dõi token khi dùng Blynk thật.
            token: ref.watch(tokenProvider),
            pollInterval: Duration(seconds: pollSeconds),
            pinMap: pinMap,
          ),
          store: store,
        );
  ref.onDispose(repo.dispose);
  return repo;
});

final issueProvider = StreamProvider<DeviceIssue>(
  (ref) => ref.watch(deviceRepositoryProvider).issueStream(),
);

/// Động cơ đang chạy? Ưu tiên trạng thái do thiết bị báo, không có thì dùng
/// trạng thái công tắc trong app.
bool isMotorRunning(Ref ref, TelemetryData d) =>
    d.motorOn ?? ref.read(motorControllerProvider).enabled;

/// Mẫu đo đã được tính lại mức cảnh báo bằng ngưỡng hiện tại.
final telemetryProvider = StreamProvider<TelemetryData>((ref) {
  final repo = ref.watch(deviceRepositoryProvider);
  return repo.telemetryStream().map(
    // ref.read: đổi ngưỡng không làm khởi động lại luồng dữ liệu.
    (d) => WarningEvaluator.apply(
      d,
      ref.read(thresholdsProvider),
      // Động cơ tắt có chủ ý thì không cảnh báo tốc độ.
      motorRunning: ref.read(motorControllerProvider).enabled,
    ),
  );
});

final latestTelemetryProvider = Provider<TelemetryData?>(
  (ref) => ref.watch(telemetryProvider).value,
);

final connectionProvider = StreamProvider<bool>(
  (ref) => ref.watch(deviceRepositoryProvider).connectionStream(),
);

/// null = chưa biết (đang kết nối), true/false = trạng thái thật.
final connectionStateProvider = Provider<bool?>(
  (ref) => ref.watch(connectionProvider).value,
);

/// Chỉ true khi chắc chắn đang kết nối.
final isConnectedProvider = Provider<bool>(
  (ref) => ref.watch(connectionStateProvider) ?? false,
);

/// Tick mỗi giây để cập nhật "Cập nhật X giây trước".
final secondTickerProvider = StreamProvider<DateTime>(
  (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
);

/// Cửa sổ trượt các mẫu gần nhất cho biểu đồ "Trực tiếp".
class LiveBufferNotifier extends Notifier<List<TelemetryData>> {
  @override
  List<TelemetryData> build() {
    ref.listen(telemetryProvider, (_, next) {
      final d = next.value;
      if (d == null) return;
      final list = [...state, d];
      state = list.length > kLiveWindowPoints
          ? list.sublist(list.length - kLiveWindowPoints)
          : list;
    });
    return const [];
  }
}

final liveBufferProvider =
    NotifierProvider<LiveBufferNotifier, List<TelemetryData>>(
      LiveBufferNotifier.new,
    );

/// Trạng thái công tắc động cơ. Chỉ đổi sau khi lệnh gửi thành công.
class MotorState {
  const MotorState({required this.enabled, this.busy = false});
  final bool enabled;
  final bool busy;
}

class MotorController extends Notifier<MotorState> {
  @override
  MotorState build() {
    // Đổi nguồn dữ liệu thì trạng thái công tắc được khởi tạo lại.
    // LƯU Ý: provider này KHÔNG được phụ thuộc telemetryProvider (telemetryProvider
    // đọc trạng thái động cơ để tính cảnh báo -> sẽ thành vòng phụ thuộc).
    // Việc đồng bộ từ thiết bị nằm ở motorSyncProvider.
    ref.watch(deviceRepositoryProvider);
    return const MotorState(enabled: true);
  }

  /// Đồng bộ công tắc theo trạng thái thật do thiết bị báo.
  /// Bỏ qua khi đang gửi lệnh để không giật công tắc.
  void syncFromDevice(bool on) {
    if (!state.busy && on != state.enabled) state = MotorState(enabled: on);
  }

  DeviceRepository get _repo => ref.read(deviceRepositoryProvider);

  /// Trả về true nếu thành công; false -> UI báo lỗi (công tắc giữ nguyên).
  Future<bool> setEnabled(bool value) async {
    if (state.busy) return false;
    state = MotorState(enabled: state.enabled, busy: true);
    final ok = await _repo.sendCommand(DeviceCommand.motorEnable(value));
    state = MotorState(enabled: ok ? value : state.enabled);
    return ok;
  }

  Future<bool> emergencyStop() async {
    if (state.busy) return false;
    state = MotorState(enabled: state.enabled, busy: true);
    final ok = await _repo.sendCommand(const DeviceCommand.emergencyStop());
    state = MotorState(enabled: ok ? false : state.enabled);
    return ok;
  }

  Future<bool> muteBuzzer() =>
      _repo.sendCommand(const DeviceCommand.buzzerMute(true));
}

final motorControllerProvider = NotifierProvider<MotorController, MotorState>(
  MotorController.new,
);

/// Tab đang mở (0 Trực tiếp, 1 Lịch sử, 2 Cài đặt). Là provider để banner
/// lỗi có thể đưa người dùng tới Cài đặt.
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);

/// Giữ công tắc động cơ khớp với trạng thái do thiết bị báo (nếu thiết bị có báo).
/// Được kích hoạt một lần từ AppShell.
final motorSyncProvider = Provider<void>((ref) {
  ref.listen(telemetryProvider, (_, next) {
    final on = next.value?.motorOn;
    if (on != null) {
      ref.read(motorControllerProvider.notifier).syncFromDevice(on);
    }
  });
});
