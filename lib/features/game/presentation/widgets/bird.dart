import 'package:flutter/material.dart';

class Bird extends StatelessWidget {
  static const hitboxWidthFactor = 0.80;
  static const hitboxHeightFactor = 0.64;
  static const visibleCenterOffsetFactor = 0.08;

  final double size;
  final bool dying;
  final Color reflectionTint;

  const Bird({
    super.key,
    this.size = 100,
    this.dying = false,
    this.reflectionTint = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                reflectionTint.withValues(alpha: 0.3),
                reflectionTint.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0, 0.58, 1],
            ).createShader(bounds),
            child: Image.asset(
              'assets/images/catrronbird.gif',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            left: size * 0.59,
            top: size * 0.485,
            width: size * 0.15,
            height: size * 0.115,
            child: const CustomPaint(painter: _StableEyePainter()),
          ),
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

class _StableEyePainter extends CustomPainter {
  const _StableEyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final eye = Path()
      ..moveTo(size.width * 0.04, size.height * 0.52)
      ..cubicTo(size.width * 0.1, size.height * 0.18, size.width * 0.34,
          size.height * 0.02, size.width * 0.62, size.height * 0.06)
      ..cubicTo(size.width * 0.87, size.height * 0.08, size.width * 0.98,
          size.height * 0.3, size.width * 0.96, size.height * 0.55)
      ..cubicTo(size.width * 0.94, size.height * 0.84, size.width * 0.75,
          size.height * 0.97, size.width * 0.52, size.height * 0.95)
      ..cubicTo(size.width * 0.27, size.height * 0.94, size.width * 0.08,
          size.height * 0.78, size.width * 0.04, size.height * 0.52)
      ..close();
    canvas.drawPath(eye, Paint()..color = const Color(0xFFFFFEFA));
    canvas.drawPath(
      eye,
      Paint()
        ..color = const Color(0xFF351719)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.55),
        width: size.width * 0.39,
        height: size.height * 0.72,
      ),
      Paint()..color = const Color(0xFF271215),
    );
    canvas.drawCircle(
      Offset(size.width * 0.73, size.height * 0.35),
      size.width * 0.07,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _StableEyePainter oldDelegate) => false;
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
