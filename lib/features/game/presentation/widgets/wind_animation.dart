import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Occasional, lightweight gusts that drift across the sky behind the scenery.
class WindAnimation extends StatefulWidget {
  const WindAnimation({super.key});

  @override
  State<WindAnimation> createState() => _WindAnimationState();
}

class _WindAnimationState extends State<WindAnimation>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  Timer? _nextGust;
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _scheduleGust();
  }

  void _scheduleGust() {
    if (!mounted) return;
    _nextGust?.cancel();
    _nextGust = Timer(
      Duration(seconds: 3 + _random.nextInt(7)),
      () {
        if (!mounted) return;
        setState(() => _seed = _random.nextInt(1 << 30));
        _controller.forward(from: 0).whenComplete(_scheduleGust);
      },
    );
  }

  @override
  void dispose() {
    _nextGust?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _WindPainter(animation: _controller, seed: _seed),
      ),
    );
  }
}

class _WindPainter extends CustomPainter {
  final Animation<double> animation;
  final int seed;
  late final List<double> _heightOffsets = _makeHeightOffsets();
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2;

  _WindPainter({required this.animation, required this.seed})
      : super(repaint: animation);

  List<double> _makeHeightOffsets() {
    final random = math.Random(seed);
    return List.generate(6, (_) => 0.1 + random.nextDouble() * 0.68);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final progress = animation.value;
    final fade = math.sin(progress * math.pi).clamp(0.0, 1.0).toDouble();
    if (fade <= 0) return;

    final travel = (progress * 1.55 - 0.3) * size.width;
    _paint.color = Colors.white.withValues(alpha: fade * 0.42);

    for (var index = 0; index < _heightOffsets.length; index++) {
      final startX = travel + index * size.width * 0.055;
      final y = _heightOffsets[index] * size.height;
      final length = size.width * (0.12 + (index % 3) * 0.025);
      final path = Path()
        ..moveTo(startX, y)
        ..cubicTo(
          startX + length * 0.32,
          y - 5,
          startX + length * 0.7,
          y + 5,
          startX + length,
          y,
        );
      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.animation != animation;
}
