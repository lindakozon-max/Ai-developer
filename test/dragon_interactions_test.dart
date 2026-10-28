import 'package:flame/components.dart';
import 'package:flappy_bird/domain/dragon.dart';
import 'package:flappy_bird/domain/horse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'farm_interactions_test.dart' as helpers;
import 'horse_market_ui_test.dart' show tapVisible;

void main() {
  testWidgets(
    'elemental dragons breed hybrids, fly, resize and remove safely',
    (tester) async {
      final game = await helpers.openFarm(tester);
      game.onHorseTapped(game.horses.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 80; i++) {
        await tester.tap(find.text('Pet (+10 coins)'));
        await tester.pump();
      }
      await helpers.closePanel(tester);
      await tapVisible(tester, find.text('Farm market'));
      await tapVisible(tester, find.text('Buy fire dragon (250 coins)'));
      await tapVisible(tester, find.text('Buy ice dragon (250 coins)'));
      await helpers.closePanel(tester);
      expect(game.dragons.length, 2);
      final fire = game.dragons.first;
      final ice = game.dragons.last;
      game.onDragonTapped!(fire);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<FilledButton>(helpers.buttonWithLabel('Ride dragon'))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.byKey(const ValueKey('dragon-partner')));
      await tapVisible(tester, find.textContaining(ice.dragon.name).last);
      await tapVisible(tester, find.text('Breed a dragon (80 coins)'));
      expect(game.dragons.length, 3);
      final hybrid = game.dragons.last;
      expect(hybrid.dragon.elements, {DragonElement.fire, DragonElement.ice});
      expect(hybrid.dragon.parentIds, [fire.id, ice.id]);
      expect(find.textContaining('hatched!'), findsOneWidget);
      await helpers.closePanel(tester);

      // The roster provides care access even when creatures overlap in a pen.
      await tapVisible(tester, find.text('Your animals'));
      await tapVisible(tester, find.text(hybrid.dragon.name));
      await tapVisible(tester, find.text('Sky dragon saddle • 85 coins'));
      expect(hybrid.dragon.saddle, SaddleType.sky);
      await tapVisible(tester, find.text('Ride dragon'));
      expect(hybrid.isRidden, isTrue);
      expect(game.player!.isRiding, isTrue);
      expect(game.player!.position, hybrid.position);
      final before = hybrid.position.clone();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      game.update(.1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      expect(hybrid.position.x, closeTo(before.x + 34, .01));
      final held = await tester.startGesture(
        tester.getCenter(find.byTooltip('Move down')),
      );
      game.update(.1);
      await held.up();
      final released = hybrid.position.clone();
      game.update(.1);
      expect(hybrid.position, released);
      expect(game.player!.position, hybrid.position);
      tester.view.physicalSize = const Size(320, 640);
      await tester.pump();
      expect(game.player!.position, hybrid.position);
      expect(hybrid.position.x, inInclusiveRange(0, game.size.x));

      game.onDragonTapped!(hybrid);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Remove dragon'));
      await tapVisible(tester, find.text('Keep animal'));
      expect(game.dragons, contains(hybrid));
      expect(hybrid.isRidden, isTrue);
      await tapVisible(tester, find.text('Remove dragon'));
      await tapVisible(tester, find.text('Remove'));
      expect(game.dragons, isNot(contains(hybrid)));
      expect(game.player!.isRiding, isFalse);
      expect(find.text('Dismount'), findsNothing);

      // Compatibility: every shared saddle and elemental combination renders.
      final horse = game.horses.first;
      for (final saddle in SaddleType.values) {
        horse.horse = horse.horse.copyWith(saddle: saddle);
        fire.dragon = fire.dragon.copyWith(saddle: saddle);
        await tester.pump(const Duration(milliseconds: 40));
      }
      for (final first in DragonElement.values) {
        for (final second in DragonElement.values) {
          fire.dragon = Dragon(
            id: fire.id,
            name: 'Hybrid',
            elements: {first, second},
            saddle: SaddleType.ember,
          );
          game.update(.1);
          await tester.pump(const Duration(milliseconds: 40));
          expect(
            game
                .enclosure(6)
                .contains(Offset(fire.position.x, fire.position.y)),
            isTrue,
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removing animals and a mounted horse clears controls and roster',
    (tester) async {
      final game = await helpers.openFarm(tester);
      final animal = game.animals.first;
      game.onAnimalTapped(animal);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Remove animal'));
      await tapVisible(tester, find.text('Remove'));
      expect(game.animals.length, 4);
      expect(game.animals, isNot(contains(animal)));

      final horse = game.horses.first;
      game.onHorseTapped(horse);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Classic saddle • 30 coins'));
      await tapVisible(tester, find.text('Ride horse'));
      game.onHorseTapped(horse);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tapVisible(tester, find.text('Remove horse'));
      await tapVisible(tester, find.text('Remove'));
      expect(game.horses, isEmpty);
      expect(game.player!.isRiding, isFalse);
      final before = game.player!.position.clone();
      game.movePlayer(Vector2(8, 0));
      expect(game.player!.position.x, greaterThan(before.x));
      await tapVisible(tester, find.text('Your animals'));
      expect(find.text(horse.horse.name), findsNothing);
      await helpers.closePanel(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
