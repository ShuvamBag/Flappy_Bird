import 'package:flutter/material.dart';

class Bird extends StatelessWidget {
  final double size;
  final bool dying;

  const Bird({super.key, this.size = 100, this.dying = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/catrronbird.gif'),
          if (dying)
            Positioned(
              left: size * 0.59,
              top: size * 0.47,
              width: size * 0.17,
              height: size * 0.17,
              child: const CustomPaint(painter: _DizzyEyePainter()),
            ),
        ],
      ),
    );
  }
}

class _DizzyEyePainter extends CustomPainter {
  const _DizzyEyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final eye = Offset.zero & size;
    canvas.drawOval(
      eye,
      Paint()..color = const Color(0xFFFFFDF8),
    );
    canvas.drawOval(
      eye,
      Paint()
        ..color = const Color(0xFF542020)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.08,
    );

    final cross = Paint()
      ..color = const Color(0xFF542020)
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.7),
      cross,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.7),
      cross,
    );
  }

  @override
  bool shouldRepaint(covariant _DizzyEyePainter oldDelegate) => false;
}
