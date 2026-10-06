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
          Positioned(
            left: size * 0.62,
            top: size * 0.50,
            width: size * 0.11,
            height: size * 0.09,
            child: const ClipOval(
              child: ColoredBox(color: Color(0xFFFFFEFA)),
            ),
          ),
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
