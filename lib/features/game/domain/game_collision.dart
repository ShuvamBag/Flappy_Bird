import 'dart:ui';

bool overlapsAtAlignment({
  required Size playfieldSize,
  required Offset firstAlignment,
  required Size firstSize,
  required Offset secondAlignment,
  required Size secondSize,
}) {
  final firstRect = _rectAtAlignment(
    playfieldSize,
    firstAlignment,
    firstSize,
  );
  final secondRect = _rectAtAlignment(
    playfieldSize,
    secondAlignment,
    secondSize,
  );
  return firstRect.overlaps(secondRect);
}

/// Checks a bird against the visible parts of a tree: an oval canopy and its
/// narrow trunk. The rectangular widget bounds include transparent corners.
bool overlapsTreeAtAlignment({
  required Size playfieldSize,
  required Offset birdAlignment,
  required Size birdSize,
  required Offset treeAlignment,
  required Size treeSize,
  required double canopyHeight,
}) {
  final bird = _rectAtAlignment(playfieldSize, birdAlignment, birdSize);
  final tree = _rectAtAlignment(playfieldSize, treeAlignment, treeSize);
  final canopy = Rect.fromLTWH(
    tree.left + tree.width * 0.04,
    tree.top,
    tree.width * 0.92,
    canopyHeight,
  );
  if (_rectOverlapsOval(bird, canopy)) return true;

  // The trunk is narrower than the canopy and starts just below its center.
  final trunkTop = tree.top + canopyHeight * 0.68;
  final trunk = Rect.fromLTWH(
    tree.left + tree.width * 0.39,
    trunkTop,
    tree.width * 0.22,
    tree.bottom - trunkTop,
  );
  return bird.overlaps(trunk);
}

bool _rectOverlapsOval(Rect rect, Rect oval) {
  final closestX = oval.center.dx.clamp(rect.left, rect.right);
  final closestY = oval.center.dy.clamp(rect.top, rect.bottom);
  final dx = (closestX - oval.center.dx) / (oval.width / 2);
  final dy = (closestY - oval.center.dy) / (oval.height / 2);
  return dx * dx + dy * dy <= 1;
}

Rect _rectAtAlignment(Size playfieldSize, Offset alignment, Size size) {
  final center = Offset(
    (alignment.dx + 1) * (playfieldSize.width - size.width) / 2 +
      size.width / 2,
    (alignment.dy + 1) * (playfieldSize.height - size.height) / 2 +
      size.height / 2,
  );
  return Rect.fromCenter(
      center: center, width: size.width, height: size.height);
}
