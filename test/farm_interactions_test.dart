import 'package:flame/game.dart';
import 'package:flappy_bird/domain/animal.dart';
import 'package:flappy_bird/domain/horse.dart';
import 'package:flappy_bird/farm_game.dart';
import 'package:flappy_bird/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FarmGame> openFarm(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: FarmScreen()));
  await tester.pump(const Duration(milliseconds: 500));
  return tester
      .widget<GameWidget<FarmGame>>(find.byType(GameWidget<FarmGame>))
      .game!;
}

Future<void> closePanel(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(SingleChildScrollView))).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder buttonWithLabel(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is FilledButton),
);

void main() {
  testWidgets(
    'market buys a selected animal coat and horse coat with live balance',
    (tester) async {
      final game = await openFarm(tester);
      expect(game.animals.length, 5);
      expect(game.horses.length, 1);
      await tester.tap(find.text('Farm market'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('animal-kind')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Donkey').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('variant-donkey')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Spotted').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Buy donkey (45 coins)'));
      await tester.pump();
      expect(game.animals.last.animal.kind, AnimalKind.donkey);
      expect(game.animals.last.animal.variant, AnimalVariant.spotted);
      expect(find.textContaining('55 coins'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('animal-kind')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Horse').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('variant-horse')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Black').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Buy horse (50 coins)'));
      await tester.pump();
      expect(game.horses.last.variant, HorseVariant.black);
      expect(game.horses.last.id, 'horse-2');
      expect(find.textContaining('5 coins'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(buttonWithLabel('Buy horse (50 coins)'))
            .onPressed,
        isNull,
      );
      await closePanel(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saddles refresh immediately and mounted horse follows held controls',
    (tester) async {
      final game = await openFarm(tester);
      final horse = game.horses.first;
      game.onHorseTapped(horse);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<FilledButton>(buttonWithLabel('Ride horse')).onPressed,
        isNull,
      );
      await tester.tap(find.text('Classic saddle • 30 coins'));
      await tester.pump();
      expect(horse.horse.saddle, SaddleType.classic);
      expect(find.text('Classic saddle • Fitted'), findsOneWidget);
      expect(find.textContaining('70 coins'), findsOneWidget);
      await tester.tap(find.text('Western saddle • 45 coins'));
      await tester.pump();
      expect(horse.horse.saddle, SaddleType.western);
      expect(find.text('Classic saddle • Equip'), findsOneWidget);
      await tester.tap(find.text('Classic saddle • Equip'));
      await tester.pump();
      expect(horse.horse.saddle, SaddleType.classic);
      expect(find.textContaining('25 coins'), findsOneWidget);
      await tester.tap(find.text('Ride horse'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(horse.isRidden, isTrue);
      expect(game.player!.isRiding, isTrue);
      expect(game.player!.position, horse.position);
      final before = horse.position.clone();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      game.update(.1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      expect(horse.position.x, closeTo(before.x + 29, .01));
      expect(game.player!.position, horse.position);
      final stopped = horse.position.clone();
      game.update(.1);
      expect(horse.position, stopped);
      final press = await tester.startGesture(
        tester.getCenter(find.byTooltip('Move down')),
      );
      game.update(.1);
      expect(horse.position.y, greaterThan(stopped.y));
      await press.up();
      final released = horse.position.clone();
      game.update(.1);
      expect(horse.position, released);
      await tester.tap(find.text('Dismount'));
      await tester.pump();
      expect(horse.isRidden, isFalse);
      expect(game.player!.isRiding, isFalse);
      expect((game.player!.position - horse.position).length, greaterThan(0));
      final unmountedHorse = horse.position.clone();
      game.movePlayer(Vector2(12, 0));
      expect(horse.position, unmountedHorse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'every animal and saddle renders, animates, and stays inside resized farm',
    (tester) async {
      final game = await openFarm(tester, size: const Size(800, 1000));
      for (final kind in AnimalKind.values) {
        for (final variant in AnimalVariant.values) {
          game.addAnimal(
            Animal(
              id: '${kind.name}-${variant.name}',
              name: 'Friend',
              kind: kind,
              variant: variant,
              needs: const AnimalNeeds(hunger: 50, happiness: 50),
            ),
          );
        }
      }
      for (final variant in HorseVariant.values) {
        game.addHorse(
          Horse(
            id: 'test-${variant.name}',
            name: 'Horse',
            variant: variant,
            saddle: SaddleType.values[variant.index],
            ownedSaddles: {SaddleType.values[variant.index]},
          ),
        );
      }
      await tester.pump(const Duration(milliseconds: 50));
      final phase = game.animals.first.phase;
      // Step bounded frames to exercise wandering and animation without relying on random directions.
      for (var frame = 0; frame < 50; frame++) {
        game.update(.1);
      }
      await tester.pump(const Duration(milliseconds: 50));
      expect(game.animals.first.phase, greaterThan(phase));
      expect(game.animals.length, 30);
      expect(game.horses.length, 6);
      tester.view.physicalSize = const Size(320, 640);
      await tester.pump();
      for (final animal in [...game.animals, ...game.horses]) {
        expect(animal.position.x, inInclusiveRange(0, game.size.x));
        expect(animal.position.y, inInclusiveRange(0, game.size.y));
      }
      game.movePlayer(Vector2(-10000, 10000));
      expect(game.player!.position.x, greaterThanOrEqualTo(24));
      expect(game.player!.position.y, lessThanOrEqualTo(game.size.y - 24));
      expect(tester.takeException(), isNull);
    },
  );
}
