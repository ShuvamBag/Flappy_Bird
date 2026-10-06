import 'package:flutter/material.dart';

class TreeObstacle extends StatelessWidget {
  final double width;
  final double height;
  final int variant;

  static const variantCount = 5;
  static const heightFactors = [0.30, 0.37, 0.44, 0.51, 0.58];

  const TreeObstacle({
    super.key,
    required this.width,
    required this.height,
    this.variant = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TreePainter(variant % variantCount),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final int variant;

  const _TreePainter(this.variant);

  static const _bark = Color(0xFF57391F);
  static const _barkLight = Color(0xFF80532A);
  static const _leafDark = Color(0xFF286B32);
  static const _leaf = Color(0xFF4D963F);
  static const _leafLight = Color(0xFF78B84D);

  @override
  void paint(Canvas canvas, Size size) {
    final canopyHeight = size.height * 0.34;
    final centerX = size.width / 2;
    final trunkTop = canopyHeight * 0.67;

    final trunkPath = Path()
      ..moveTo(centerX - size.width * 0.095, trunkTop)
      ..lineTo(centerX + size.width * 0.095, trunkTop)
      ..lineTo(centerX + size.width * 0.065, size.height)
      ..lineTo(centerX - size.width * 0.065, size.height)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = _bark);
    canvas.drawRect(
      Rect.fromLTRB(
        centerX - size.width * 0.025,
        trunkTop + canopyHeight * 0.12,
        centerX + size.width * 0.025,
        size.height,
      ),
      Paint()..color = _barkLight,
    );

    switch (variant) {
      case 0:
        _drawRoundCrown(canvas, size, canopyHeight);
      case 1:
        _drawEvergreen(canvas, size, canopyHeight);
      case 2:
        _drawPoplar(canvas, size, canopyHeight);
      case 3:
        _drawUmbrellaCrown(canvas, size, canopyHeight);
      case 4:
        _drawTopiary(canvas, size, canopyHeight);
    }

    // A soft upper-left sheen gives the canopy volume and catches the scene light.
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.16, canopyHeight * 0.12, size.width * 0.35,
          canopyHeight * 0.2),
      Paint()..color = const Color(0x447EF3A0),
    );
    canvas.drawRect(
      Rect.fromLTWH(
          centerX - size.width * 0.025,
          trunkTop + canopyHeight * 0.12,
          size.width * 0.025,
          size.height * 0.82),
      Paint()..color = const Color(0x44FFF0B8),
    );
  }

  void _drawRoundCrown(Canvas canvas, Size size, double canopyHeight) {
    final width = size.width;
    canvas.drawOval(
      Rect.fromLTWH(
          width * 0.04, canopyHeight * 0.08, width * 0.92, canopyHeight * 0.84),
      Paint()..color = _leafDark,
    );
    canvas.drawCircle(Offset(width * 0.32, canopyHeight * 0.48),
        canopyHeight * 0.37, Paint()..color = _leaf);
    canvas.drawCircle(Offset(width * 0.62, canopyHeight * 0.39),
        canopyHeight * 0.39, Paint()..color = _leaf);
    canvas.drawCircle(Offset(width * 0.76, canopyHeight * 0.59),
        canopyHeight * 0.25, Paint()..color = _leafLight);
  }

  void _drawEvergreen(Canvas canvas, Size size, double canopyHeight) {
    final width = size.width;
    for (var tier = 0; tier < 3; tier++) {
      final top = canopyHeight * (0.03 + tier * 0.27);
      final tierWidth = width * (0.45 + tier * 0.23);
      final path = Path()
        ..moveTo(width / 2, top)
        ..lineTo(width / 2 + tierWidth / 2, top + canopyHeight * 0.55)
        ..lineTo(width / 2 - tierWidth / 2, top + canopyHeight * 0.55)
        ..close();
      canvas.drawPath(path, Paint()..color = _leafDark);
      canvas.drawPath(
        Path()
          ..moveTo(width / 2, top + canopyHeight * 0.1)
          ..lineTo(width / 2 - tierWidth * 0.16, top + canopyHeight * 0.42)
          ..lineTo(width / 2, top + canopyHeight * 0.35)
          ..close(),
        Paint()..color = _leaf,
      );
    }
  }

  void _drawPoplar(Canvas canvas, Size size, double canopyHeight) {
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.23, 0, size.width * 0.54, canopyHeight),
      Paint()..color = _leafDark,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.34, canopyHeight * 0.08, size.width * 0.31,
          canopyHeight * 0.73),
      Paint()..color = _leaf,
    );
    canvas.drawCircle(
      Offset(size.width * 0.46, canopyHeight * 0.3),
      canopyHeight * 0.14,
      Paint()..color = _leafLight,
    );
  }

  void _drawUmbrellaCrown(Canvas canvas, Size size, double canopyHeight) {
    final width = size.width;
    final canopy = Path()
      ..moveTo(width * 0.04, canopyHeight * 0.63)
      ..quadraticBezierTo(
          width * 0.1, canopyHeight * 0.08, width * 0.5, canopyHeight * 0.1)
      ..quadraticBezierTo(
          width * 0.91, canopyHeight * 0.05, width * 0.96, canopyHeight * 0.64)
      ..quadraticBezierTo(
          width * 0.51, canopyHeight * 0.87, width * 0.04, canopyHeight * 0.63)
      ..close();
    canvas.drawPath(canopy, Paint()..color = _leafDark);
    canvas.drawOval(
      Rect.fromLTWH(
          width * 0.18, canopyHeight * 0.18, width * 0.53, canopyHeight * 0.4),
      Paint()..color = _leaf,
    );
    canvas.drawCircle(
      Offset(width * 0.72, canopyHeight * 0.43),
      canopyHeight * 0.2,
      Paint()..color = _leafLight,
    );
  }

  void _drawTopiary(Canvas canvas, Size size, double canopyHeight) {
    final width = size.width;
    canvas.drawCircle(
      Offset(width * 0.5, canopyHeight * 0.3),
      canopyHeight * 0.3,
      Paint()..color = _leafDark,
    );
    canvas.drawCircle(
      Offset(width * 0.34, canopyHeight * 0.61),
      canopyHeight * 0.28,
      Paint()..color = _leaf,
    );
    canvas.drawCircle(
      Offset(width * 0.68, canopyHeight * 0.62),
      canopyHeight * 0.29,
      Paint()..color = _leafDark,
    );
    canvas.drawCircle(
      Offset(width * 0.45, canopyHeight * 0.28),
      canopyHeight * 0.14,
      Paint()..color = _leafLight,
    );
    canvas.drawCircle(
      Offset(width * 0.75, canopyHeight * 0.51),
      canopyHeight * 0.1,
      Paint()..color = _leafLight,
    );
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) =>
      oldDelegate.variant != variant;
}
