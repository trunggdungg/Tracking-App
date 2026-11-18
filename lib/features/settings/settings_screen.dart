import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/blynk/blynk_api.dart';
import '../../data/blynk/blynk_config.dart';
import '../../data/blynk/pin_map.dart';
import '../../data/local/app_settings.dart';
import '../../domain/thresholds.dart';
import '../../core/theme.dart';
import 'blynk_messages.dart';

/// Màn hình Cài đặt. Mọi thay đổi chỉ có hiệu lực khi bấm "Lưu cài đặt".
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _useMock;
  late int _pollSeconds;
  bool _showToken = false;

  final _token = TextEditingController();
  final _host = TextEditingController();
  final _retention = TextEditingController();
  final _pins = {for (final f in PinMap.fields) f.key: TextEditingController()};
  final _thr = {for (final k in _thresholdKeys) k: TextEditingController()};

  static const _thresholdKeys = [
    'rpmLow',
    'rpmHigh',
    'rpmMax',
    'tempWarn',
    'tempDanger',
    'vibrationDanger',
  ];

  // Mỗi ô có một khóa (theo thứ tự hiển thị) để cuộn tới ô lỗi đầu tiên.
  final _fieldKeys = <String, GlobalKey<FormFieldState<String>>>{};
  GlobalKey<FormFieldState<String>> _keyFor(String id) =>
      _fieldKeys.putIfAbsent(id, GlobalKey<FormFieldState<String>>.new);

  void _revealFirstError() {
    for (final k in _fieldKeys.values) {
      final ctx = k.currentContext;
      if (k.currentState?.hasError == true && ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
        );
        return;
      }
    }
  }

  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _useMock = s.useMock;
    _pollSeconds = s.pollSeconds;
    _host.text = s.host;
    _retention.text = '${s.retentionDays}';
    _token.text = ref.read(tokenProvider) ?? '';
    _fillPins(s.pinMap);
    _fillThresholds(s.thresholds);
  }

  @override
  void dispose() {
    for (final c in [
      _token,
      _host,
      _retention,
      ..._pins.values,
      ..._thr.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  void _fillPins(PinMap p) {
    final m = p.toMap();
    for (final f in PinMap.fields) {
      _pins[f.key]!.text = m[f.key]?.toString() ?? '';
    }
  }

  void _fillThresholds(Thresholds t) {
    _thr['rpmLow']!.text = _num(t.rpmLow);
    _thr['rpmHigh']!.text = _num(t.rpmHigh);
    _thr['rpmMax']!.text = _num(t.rpmMax);
    _thr['tempWarn']!.text = _num(t.tempWarn);
    _thr['tempDanger']!.text = _num(t.tempDanger);
    _thr['vibrationDanger']!.text = _num(t.vibrationDanger);
  }

  PinMap _readPins() => PinMap.fromMap({
    for (final f in PinMap.fields)
      f.key: int.tryParse(_pins[f.key]!.text.trim()),
  });

  double _d(String key) =>
      double.parse(_thr[key]!.text.trim().replaceAll(',', '.'));

  // ---- Kiểm tra từng ô ----------------------------------------------------

  String? _validatePin(String? v, {required bool required}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return required ? 'Bắt buộc' : null;
    final n = int.tryParse(t);
    if (n == null || n < 0 || n > 255) return '0-255';
    return null;
  }

  String? _validatePositive(String? v) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Số > 0';
    return null;
  }

  String? _validateRetention(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 1 || n > 365) return '1-365 ngày';
    return null;
  }

  /// Ràng buộc giữa các ngưỡng (sau khi từng ô đã hợp lệ).
  String? _crossCheck() {
    if (_d('rpmLow') >= _d('rpmHigh')) {
      return 'Tốc độ thấp phải nhỏ hơn tốc độ cao.';
    }
    if (_d('rpmHigh') > _d('rpmMax')) {
      return 'Tốc độ cao không được vượt thang tối đa.';
    }
    if (_d('tempWarn') >= _d('tempDanger')) {
      return 'Nhiệt độ cảnh báo phải nhỏ hơn nhiệt độ nguy hiểm.';
    }
    if (_d('tempDanger') > const Thresholds().tempMax) {
      return 'Nhiệt độ nguy hiểm không được vượt ${const Thresholds().tempMax.round()} °C (thang gauge).';
    }
    return null;
  }

  // ---- Hành động ------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Có ô chưa hợp lệ, hãy kiểm tra lại.');
      _revealFirstError();
      return;
    }
    final cross = _crossCheck();
    if (cross != null) {
      _snack(cross);
      return;
    }

    final settings = AppSettings(
      useMock: _useMock,
      host: normalizeHost(_host.text),
      pollSeconds: _pollSeconds,
      retentionDays: int.parse(_retention.text.trim()),
      thresholds: Thresholds(
        rpmLow: _d('rpmLow'),
        rpmHigh: _d('rpmHigh'),
        rpmMax: _d('rpmMax'),
        tempWarn: _d('tempWarn'),
        tempDanger: _d('tempDanger'),
        vibrationDanger: _d('vibrationDanger'),
      ),
      pinMap: _readPins(),
    );

    // Cả hai cập nhật state đồng bộ nên repository chỉ dựng lại một lần.
    final tokenFuture = ref.read(tokenProvider.notifier).save(_token.text);
    final settingsFuture = ref.read(settingsProvider.notifier).save(settings);
    try {
      await Future.wait([tokenFuture, settingsFuture]);
      _snack('Đã lưu cài đặt.');
    } catch (_) {
      _snack('Lưu cài đặt thất bại, hãy thử lại.');
    }
  }

  Future<void> _testConnection() async {
    final token = _token.text.trim();
    if (token.isEmpty) {
      setState(() {
        _testOk = false;
        _testResult = 'Hãy nhập token trước.';
      });
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final api = BlynkApi(host: _host.text, token: token);
    final r = await api.test(_readPins());
    api.close();
    if (!mounted) return;

    String text;
    var ok = false;
    if (r.error != null) {
      text = r.error!.message;
    } else {
      ok = true;
      final parts = <String>['Token hợp lệ.'];
      parts.add(
        r.hardwareOnline == true
            ? 'Thiết bị đang online.'
            : 'Thiết bị đang OFFLINE.',
      );
      if (_readPins().missingRequired.isNotEmpty) {
        parts.add('Chưa điền pin tốc độ/nhiệt độ nên chưa đọc thử được.');
        ok = false;
      } else if (r.rpm != null && r.temperature != null) {
        parts.add(
          'Đọc thử: ${r.rpm!.round()} vòng/phút, ${r.temperature!.toStringAsFixed(1)} °C.',
        );
      } else {
        parts.add('Không đọc được giá trị tốc độ/nhiệt độ từ các pin đã nhập.');
        ok = false;
      }
      text = parts.join(' ');
    }
    setState(() {
      _testing = false;
      _testOk = ok;
      _testResult = text;
    });
  }

  void _resetDefaults() {
    _fillPins(const PinMap());
    _fillThresholds(const Thresholds());
    _retention.text = '${const AppSettings().retentionDays}';
    setState(() => _pollSeconds = const AppSettings().pollSeconds);
    _snack('Đã khôi phục giá trị mặc định (chưa lưu).');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Giao diện --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Dùng SingleChildScrollView + Column (không phải ListView) để MỌI ô đều được
    // dựng sẵn: ListView dựng lười nên Form.validate() sẽ bỏ qua ô chưa cuộn tới.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section('Nguồn dữ liệu', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dùng dữ liệu giả (Mock)'),
                subtitle: const Text(
                  'Bật để thử giao diện khi chưa có thiết bị.',
                ),
                value: _useMock,
                onChanged: (v) => setState(() => _useMock = v),
              ),
            ]),
            const SizedBox(height: 12),
            _section('Kết nối Blynk', [
              TextFormField(
                controller: _token,
                obscureText: !_showToken,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Auth Token',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _showToken ? 'Ẩn token' : 'Hiện token',
                    icon: Icon(
                      _showToken ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _showToken = !_showToken),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: _keyFor('host'),
                controller: _host,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Máy chủ (host)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final h in kBlynkHosts)
                    ActionChip(
                      label: Text(h),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _host.text = h),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: const Text('Kiểm tra kết nối'),
                  ),
                ],
              ),
              if (_testResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testOk ? context.palette.ok : scheme.error,
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            _section('Ánh xạ pin (V<số>)', [
              Text(
                'Nhập số pin ảo của từng giá trị. Để trống nếu thiết bị không có. '
                'Tốc độ và nhiệt độ là bắt buộc để đọc dữ liệu từ Blynk.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final f in PinMap.fields) _pinRow(f),
            ]),
            const SizedBox(height: 12),
            _section('Ngưỡng cảnh báo', [
              _thrRow('rpmLow', 'Tốc độ thấp', 'vòng/phút'),
              _thrRow('rpmHigh', 'Tốc độ cao', 'vòng/phút'),
              _thrRow('rpmMax', 'Thang tốc độ tối đa', 'vòng/phút'),
              _thrRow('tempWarn', 'Nhiệt độ cảnh báo', '°C'),
              _thrRow('tempDanger', 'Nhiệt độ nguy hiểm', '°C'),
              _thrRow('vibrationDanger', 'Rung nguy hiểm', 'mm/s'),
            ]),
            const SizedBox(height: 12),
            _section('Chu kỳ cập nhật (Blynk)', [
              SegmentedButton<int>(
                segments: [
                  for (final s in AppSettings.pollOptions)
                    ButtonSegment(value: s, label: Text('$s giây')),
                ],
                selected: {_pollSeconds},
                onSelectionChanged: (v) =>
                    setState(() => _pollSeconds = v.first),
              ),
            ]),
            const SizedBox(height: 12),
            _section('Lưu trữ lịch sử', [
              _numberRow(
                id: 'retention',
                controller: _retention,
                label: 'Tự xóa dữ liệu cũ hơn',
                helper: 'ngày',
                validator: _validateRetention,
                integer: true,
              ),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu cài đặt'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resetDefaults,
              child: const Text('Khôi phục mặc định (pin, ngưỡng, chu kỳ)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _pinRow(PinField f) => _numberRow(
    id: 'pin.${f.key}',
    controller: _pins[f.key]!,
    label: f.required ? '${f.label} *' : f.label,
    helper: f.role,
    prefix: 'V',
    validator: (v) => _validatePin(v, required: f.required),
    integer: true,
  );

  Widget _thrRow(String key, String label, String unit) => _numberRow(
    id: 'thr.$key',
    controller: _thr[key]!,
    label: label,
    helper: unit, // đơn vị để dưới nhãn: ô số hẹp, để cạnh số sẽ bị đè
    validator: _validatePositive,
    integer: false,
  );

  Widget _numberRow({
    required String id,
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool integer,
    String? helper,
    String? prefix,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  if (helper != null)
                    Text(
                      helper,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: TextFormField(
              key: _keyFor(id),
              controller: controller,
              validator: validator,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.numberWithOptions(decimal: !integer),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(integer ? r'[0-9]' : r'[0-9.,]'),
                ),
              ],
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                prefixText: prefix,
                suffixText: suffix,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
