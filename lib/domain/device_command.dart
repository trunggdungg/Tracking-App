/// Lệnh điều khiển gửi xuống thiết bị. UI chỉ biết các lệnh này,
/// không biết thiết bị thực sự nhận qua Blynk pin hay MQTT topic.
sealed class DeviceCommand {
  const DeviceCommand();

  /// Bật/tắt động cơ.
  const factory DeviceCommand.motorEnable(bool enable) = MotorEnableCommand;

  /// Dừng khẩn cấp.
  const factory DeviceCommand.emergencyStop() = EmergencyStopCommand;

  /// Tắt (true) / cho phép (false) còi báo.
  const factory DeviceCommand.buzzerMute(bool mute) = BuzzerMuteCommand;
}

class MotorEnableCommand extends DeviceCommand {
  const MotorEnableCommand(this.enable);
  final bool enable;
}

class EmergencyStopCommand extends DeviceCommand {
  const EmergencyStopCommand();
}

class BuzzerMuteCommand extends DeviceCommand {
  const BuzzerMuteCommand(this.mute);
  final bool mute;
}
