import 'dart:math' as math;

import 'package:flutter/material.dart';

class LawnPainter extends CustomPainter {
  final double offset;

  const LawnPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    const bladeColors = [
      Color(0x5579CB55),
      Color(0x4472B947),
      Color(0x3A247B32),
    ];
    final random = math.Random(43);

    for (var index = 0; index < 140; index++) {
      final x =
          (random.nextDouble() * size.width - offset * size.width) % size.width;
      final y = random.nextDouble() * size.height;
      final lean = (random.nextDouble() - 0.5) * 2.4;
      final bladeLength = 1.5 + random.nextDouble() * 3.0;
      final bladePaint = Paint()
        ..color = bladeColors[index % bladeColors.length]
        ..strokeWidth = 0.8 + random.nextDouble() * 0.7
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + lean, y - bladeLength),
        bladePaint,
      );
    }
  }

  @override
  bool shouldRepaint(LawnPainter oldDelegate) => offset != oldDelegate.offset;
}

class GrassFringePainter extends CustomPainter {
  final double offset;

  const GrassFringePainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(29);
    const colors = [
      Color(0xFF276B31),
      Color(0xFF347F35),
      Color(0xFF5CA845),
      Color(0xFF80C750),
    ];

    for (var index = 0; index < 260; index++) {
      final x =
          (random.nextDouble() * size.width - offset * size.width) % size.width;
      final baseY = size.height * (0.58 + random.nextDouble() * 0.18);
      final bladeLength = size.height * (0.18 + random.nextDouble() * 0.48);
      final lean = (random.nextDouble() - 0.5) * size.width * 0.018;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..strokeWidth = 1.1 + random.nextDouble() * 1.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + lean, baseY - bladeLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GrassFringePainter oldDelegate) =>
      offset != oldDelegate.offset;
}
