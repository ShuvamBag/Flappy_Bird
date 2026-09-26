// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';

import 'package:flutterprojects/app/app.dart';
import 'package:flutterprojects/features/game/presentation/widgets/cloud.dart';
import 'package:flutterprojects/features/game/presentation/widgets/tree_obstacle.dart';

void main() {
  testWidgets('game page renders its initial state',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FlappyBirdApp());

    expect(find.text('T A P  T O  P L A Y !'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.byType(TreeObstacle), findsNWidgets(2));
    expect(find.byType(Cloud), findsNWidgets(3));
    expect(
        find.byKey(const ValueKey('ground-prop-1-bush.png')), findsOneWidget);
    expect(find.byKey(const ValueKey('grass-fringe')), findsOneWidget);
  });

  test('tree obstacles provide five distinct responsive heights', () {
    expect(TreeObstacle.heightFactors, hasLength(5));
    expect(TreeObstacle.heightFactors.toSet(), hasLength(5));
    expect(TreeObstacle.variantCount, 5);
  });

  testWidgets('game layout fits compact and wide screens',
      (WidgetTester tester) async {
    final originalSize = tester.view.physicalSize;
    final originalDevicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalDevicePixelRatio;
    });

    for (final viewport in [const Size(360, 640), const Size(844, 390)]) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const FlappyBirdApp());

      expect(find.text('SCORE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
