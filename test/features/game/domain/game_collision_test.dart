import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/game/domain/game_collision.dart';

void main() {
  test('detects overlap between aligned bird and barrier bounds', () {
    expect(
      overlapsAtAlignment(
        playfieldSize: const Size(400, 600),
        firstAlignment: const Offset(0, 0),
        firstSize: const Size(48, 48),
        secondAlignment: const Offset(0.35, 0.1),
        secondSize: const Size(72, 300),
      ),
      isTrue,
    );
  });

  test('does not report a collision when the objects are separated', () {
    expect(
      overlapsAtAlignment(
        playfieldSize: const Size(400, 600),
        firstAlignment: const Offset(0, 0),
        firstSize: const Size(48, 48),
        secondAlignment: const Offset(1, 1),
        secondSize: const Size(72, 180),
      ),
      isFalse,
    );
  });
}
