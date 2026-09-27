import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact vector crow with an angry brow and animated wing position.
class Crow extends StatelessWidget {
  final double width;
  final double height;
  final double wingPhase;

  const Crow({
    super.key,
    required this.width,
    required this.height,
    required this.wingPhase,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CrowPainter(wingPhase)),
    );
  }
}

class _CrowPainter extends CustomPainter {
  final double wingPhase;

  const _CrowPainter(this.wingPhase);

  static const _feather = Color(0xFF202532);
  static const _featherLight = Color(0xFF394151);
  static const _beak = Color(0xFFFFA62B);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width;
    final darkPaint = Paint()..color = _feather;
    final lightPaint = Paint()..color = _featherLight;
    final eyePaint = Paint()..color = Colors.white;
    final irisPaint = Paint()..color = const Color(0xFFE53935);
    final beakPaint = Paint()..color = _beak;

    // Tail and body point toward the bird as the crow flies in from the left.
    final tail = Path()
      ..moveTo(scale * 0.36, size.height * 0.52)
      ..lineTo(scale * 0.02, size.height * 0.33)
      ..lineTo(scale * 0.16, size.height * 0.59)
      ..lineTo(scale * 0.01, size.height * 0.72)
      ..lineTo(scale * 0.4, size.height * 0.72)
      ..close();
    canvas.drawPath(tail, darkPaint);
    canvas.drawOval(
      Rect.fromLTWH(
          scale * 0.16, size.height * 0.39, scale * 0.61, size.height * 0.39),
      darkPaint,
    );

    // The wing rises and falls on every game update.
    final wingLift = math.sin(wingPhase * 2.2) * size.height * 0.2;
    final wing = Path()
      ..moveTo(scale * 0.31, size.height * 0.55)
      ..quadraticBezierTo(
        scale * 0.4,
        size.height * 0.08 + wingLift,
        scale * 0.77,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        scale * 0.54,
        size.height * 0.69,
        scale * 0.31,
        size.height * 0.55,
      )
      ..close();
    canvas.drawPath(wing, lightPaint);

    canvas.drawCircle(
      Offset(scale * 0.7, size.height * 0.34),
      size.height * 0.23,
      darkPaint,
    );
    final beak = Path()
      ..moveTo(scale * 0.83, size.height * 0.32)
      ..lineTo(scale, size.height * 0.4)
      ..lineTo(scale * 0.81, size.height * 0.47)
      ..close();
    canvas.drawPath(beak, beakPaint);

    canvas.drawCircle(
      Offset(scale * 0.76, size.height * 0.31),
      size.height * 0.085,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(scale * 0.79, size.height * 0.32),
      size.height * 0.045,
      irisPaint,
    );
    canvas.drawCircle(
      Offset(scale * 0.8, size.height * 0.32),
      size.height * 0.022,
      darkPaint,
    );

    final angryBrow = Paint()
      ..color = _feather
      ..strokeWidth = size.height * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(scale * 0.68, size.height * 0.19),
      Offset(scale * 0.84, size.height * 0.255),
      angryBrow,
    );
  }

  @override
  bool shouldRepaint(covariant _CrowPainter oldDelegate) =>
      oldDelegate.wingPhase != wingPhase;
}
