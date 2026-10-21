import 'package:flappy_bird/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('farm controls move the player and animal feeding still works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: FarmScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(IconButton), findsNWidgets(4));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.tap(find.byType(IconButton).at(2));
    await tester.pump();

    final gameRect = tester.getRect(
      find.byWidgetPredicate((widget) => widget is GameWidget),
    );
    await tester.tapAt(
      Offset(gameRect.center.dx, gameRect.top + gameRect.height * .35),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Feed ('), findsOneWidget);
    tester
        .widget<FilledButton>(
          find.ancestor(
            of: find.textContaining('Feed ('),
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed!
        .call();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Feed ('), findsNothing);
  });
}
