/// MỌI ánh xạ "tên trường -> số pin ảo Blynk" nằm ở đây và chỉ ở đây.
/// Phần còn lại của app không biết V0, V1... (ngoại trừ màn hình Cài đặt
/// cho người dùng nhập số pin).
///
/// `null` = chưa cấu hình / thiết bị không có pin đó.
class PinMap {
  const PinMap({
    this.motorSwitch = 0, // theo dashboard: V0 (công tắc Động cơ)
    this.chartValue = 1, // theo dashboard: V1 (biểu đồ) - app chưa dùng
    this.emergencyStop = 2, // theo dashboard: V2 (nút "Dừng động cơ")
    this.rpm, // TODO: chưa biết - điền trong Cài đặt
    this.temperature, // TODO: chưa biết - điền trong Cài đặt
    this.warningLamp, // TODO: chưa biết - điền trong Cài đặt
    this.vibration,
    this.current,
    this.health,
    this.fault,
    this.buzzer,
    this.buzzerMute,
  });

  final int? motorSwitch;
  final int? chartValue;
  final int? emergencyStop;
  final int? rpm;
  final int? temperature;

  /// Đèn cảnh báo của thiết bị: 0 = an toàn, 1 = chú ý, từ 2 trở lên = nguy hiểm.
  final int? warningLamp;

  final int? vibration;
  final int? current;
  final int? health;
  final int? fault;

  /// Trạng thái còi (đọc): > 0 = còi đang kêu.
  final int? buzzer;

  /// Lệnh tắt còi (ghi): 1 = tắt còi.
  final int? buzzerMute;

  /// Các trường bắt buộc để đọc được dữ liệu.
  static const requiredKeys = ['rpm', 'temperature'];

  /// Khai báo trường cho màn hình Cài đặt: khóa, nhãn, có bắt buộc không.
  static const fields = <PinField>[
    PinField('motorSwitch', 'Công tắc động cơ', 'đọc + ghi'),
    PinField('emergencyStop', 'Nút dừng động cơ', 'ghi'),
    PinField('rpm', 'Tốc độ (vòng/phút)', 'đọc', required: true),
    PinField('temperature', 'Nhiệt độ (°C)', 'đọc', required: true),
    PinField('warningLamp', 'Đèn cảnh báo', 'đọc'),
    PinField('vibration', 'Rung (mm/s)', 'đọc'),
    PinField('current', 'Dòng điện (A)', 'đọc'),
    PinField('health', 'Sức khỏe (%)', 'đọc'),
    PinField('fault', 'Lỗi (chuỗi)', 'đọc'),
    PinField('buzzer', 'Trạng thái còi', 'đọc'),
    PinField('buzzerMute', 'Tắt còi', 'ghi'),
    PinField('chartValue', 'Giá trị biểu đồ', 'chưa dùng'),
  ];

  Map<String, int?> toMap() => {
    'motorSwitch': motorSwitch,
    'chartValue': chartValue,
    'emergencyStop': emergencyStop,
    'rpm': rpm,
    'temperature': temperature,
    'warningLamp': warningLamp,
    'vibration': vibration,
    'current': current,
    'health': health,
    'fault': fault,
    'buzzer': buzzer,
    'buzzerMute': buzzerMute,
  };

  /// Khóa thiếu trong [m] được coi là null (không phải giá trị mặc định),
  /// để người dùng xóa trắng một ô thì pin đó thật sự bị bỏ.
  factory PinMap.fromMap(Map<String, int?> m) => PinMap(
    motorSwitch: m['motorSwitch'],
    chartValue: m['chartValue'],
    emergencyStop: m['emergencyStop'],
    rpm: m['rpm'],
    temperature: m['temperature'],
    warningLamp: m['warningLamp'],
    vibration: m['vibration'],
    current: m['current'],
    health: m['health'],
    fault: m['fault'],
    buzzer: m['buzzer'],
    buzzerMute: m['buzzerMute'],
  );

  /// Các khóa bắt buộc còn thiếu.
  List<String> get missingRequired => [
    for (final k in requiredKeys)
      if (toMap()[k] == null) k,
  ];

  /// Các pin cần ĐỌC mỗi chu kỳ (không trùng, bỏ null).
  List<int> get readPins => {
    motorSwitch,
    rpm,
    temperature,
    warningLamp,
    vibration,
    current,
    health,
    fault,
    buzzer,
  }.whereType<int>().toList()..sort();

  @override
  bool operator ==(Object other) =>
      other is PinMap && _same(other.toMap(), toMap());

  static bool _same(Map<String, int?> a, Map<String, int?> b) =>
      a.entries.every((e) => b[e.key] == e.value);

  @override
  int get hashCode => Object.hashAll(toMap().values);
}

class PinField {
  const PinField(this.key, this.label, this.role, {this.required = false});
  final String key;
  final String label;
  final String role;
  final bool required;
}
