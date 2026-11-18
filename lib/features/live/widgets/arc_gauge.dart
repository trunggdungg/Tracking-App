import 'dart:math';

import 'package:flutter/material.dart';

/// Gauge hình cung: đường nền xám + cung màu theo tỉ lệ value/max,
/// giá trị và đơn vị ở giữa.
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.valueText,
    required this.unit,
  });

  /// 0..1 (tự cắt về khoảng này).
  final double fraction;
  final Color color;
  final Color trackColor;
  final String valueText;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(
                fraction: fraction.clamp(0.0, 1.0),
                color: color,
                trackColor: trackColor,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  unit,
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  static const _stroke = 14.0;
  // Cung kéo dài hơn nửa vòng: hai đầu hơi cong xuống dưới như mẫu thiết kế.
  static const _start = pi - 0.25;
  static const _sweep = pi + 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(
      (size.height - _stroke) / 1.25,
      size.width / 2 - _stroke,
    );
    final center = Offset(size.width / 2, _stroke / 2 + radius);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _start, _sweep, false, paint..color = trackColor);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * fraction,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor;
}
