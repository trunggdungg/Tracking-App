import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/repositories/mock_repository.dart';
import '../domain/device_command.dart';
import '../domain/device_repository.dart';
import '../domain/telemetry_data.dart';
import '../domain/thresholds.dart';
import '../domain/warning_evaluator.dart';

/// Cờ chọn repository: true = Mock. (Bước 3: lưu vào shared_preferences
/// và cho đổi trong Cài đặt.)
class UseMockNotifier extends Notifier<bool> {
  @override
  bool build() => kDefaultUseMock;

  void set(bool value) => state = value;
}

final useMockProvider = NotifierProvider<UseMockNotifier, bool>(
  UseMockNotifier.new,
);

/// ĐIỂM CHUYỂN REPOSITORY DUY NHẤT của app.
/// Thêm MqttRepository sau này chỉ cần thêm một nhánh ở đây.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final useMock = ref.watch(useMockProvider);
  // TODO(bước 3): useMock ? MockRepository() : BlynkRepository(...)
  final DeviceRepository repo = useMock ? MockRepository() : MockRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Ngưỡng cảnh báo. (Bước 3: lưu/đọc shared_preferences + màn hình Cài đặt.)
class ThresholdsNotifier extends Notifier<Thresholds> {
  @override
  Thresholds build() => const Thresholds();

  void update(Thresholds value) => state = value;
}

final thresholdsProvider = NotifierProvider<ThresholdsNotifier, Thresholds>(
  ThresholdsNotifier.new,
);

/// Mẫu đo đã được tính lại mức cảnh báo bằng ngưỡng hiện tại.
final telemetryProvider = StreamProvider<TelemetryData>((ref) {
  final repo = ref.watch(deviceRepositoryProvider);
  return repo.telemetryStream().map(
    // ref.read: đổi ngưỡng không làm khởi động lại luồng dữ liệu.
    (d) => WarningEvaluator.apply(d, ref.read(thresholdsProvider)),
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
  // TODO(bước 3): đồng bộ trạng thái ban đầu từ thiết bị (pin motorSwitch).
  @override
  MotorState build() => const MotorState(enabled: true);

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
