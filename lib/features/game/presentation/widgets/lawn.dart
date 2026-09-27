import 'dart:math' as math;

import 'package:flutter/material.dart';

class LawnPainter extends CustomPainter {
  final double offset;

  static final _blades = _createLawnBlades();

  static List<_GrassBlade> _createLawnBlades() {
    const colors = [
      Color(0x5579CB55),
      Color(0x4472B947),
      Color(0x3A247B32),
    ];
    final random = math.Random(43);
    return List.generate(60, (index) {
      final width = 0.8 + random.nextDouble() * 0.7;
      return _GrassBlade(
        x: random.nextDouble(),
        y: random.nextDouble(),
        lean: (random.nextDouble() - 0.5) * 2.4,
        length: 1.5 + random.nextDouble() * 3.0,
        paint: Paint()
          ..color = colors[index % colors.length]
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    });
  }

  const LawnPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    for (final blade in _blades) {
      final x = (blade.x * size.width - offset * size.width) % size.width;
      final y = blade.y * size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + blade.lean, y - blade.length),
        blade.paint,
      );
    }
  }

  @override
  bool shouldRepaint(LawnPainter oldDelegate) => offset != oldDelegate.offset;
}

class GrassFringePainter extends CustomPainter {
  final double offset;

  static final _blades = _createFringeBlades();

  static List<_GrassBlade> _createFringeBlades() {
    const colors = [
      Color(0xFF276B31),
      Color(0xFF347F35),
      Color(0xFF5CA845),
      Color(0xFF80C750),
    ];
    final random = math.Random(29);
    return List.generate(120, (index) {
      final strokeWidth = 1.1 + random.nextDouble() * 1.8;
      return _GrassBlade(
        x: random.nextDouble(),
        y: 0.58 + random.nextDouble() * 0.18,
        lean: (random.nextDouble() - 0.5) * 0.018,
        length: 0.18 + random.nextDouble() * 0.48,
        paint: Paint()
          ..color = colors[index % colors.length]
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    });
  }

  const GrassFringePainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    for (final blade in _blades) {
      final x = (blade.x * size.width - offset * size.width) % size.width;
      final baseY = size.height * blade.y;
      final bladeLength = size.height * blade.length;
      final lean = blade.lean * size.width;
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + lean, baseY - bladeLength),
        blade.paint,
      );
    }
  }

  @override
  bool shouldRepaint(GrassFringePainter oldDelegate) =>
      offset != oldDelegate.offset;
}

class _GrassBlade {
  final double x;
  final double y;
  final double lean;
  final double length;
  final Paint paint;

  const _GrassBlade({
    required this.x,
    required this.y,
    required this.lean,
    required this.length,
    required this.paint,
  });
}
