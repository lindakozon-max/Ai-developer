import 'package:flappy_bird/domain/farm_item.dart';
import 'package:flappy_bird/domain/horse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'farm_interactions_test.dart' as helpers;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('buy Friesian, breed foal, equip unlocked style and buy dragon', (
    tester,
  ) async {
    final game = await helpers.openFarm(tester);
    final original = game.horses.first;
    game.onHorseTapped(original);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Existing pet rewards fund the market without a test-only game state.
    for (var i = 0; i < 40; i++) {
      await tester.tap(find.text('Pet (+10 coins)'));
      await tester.pump();
    }
    await helpers.closePanel(tester);
    await tapVisible(tester, find.text('Farm market'));
    await tapVisible(tester, find.byKey(const ValueKey('horse-breed')));
    await tapVisible(tester, find.text('Friesian').last);
    await tapVisible(tester, find.text('Buy horse (120 coins)'));
    expect(game.horses.last.horse.breed, HorseBreed.friesian);
    expect(game.horses.last.variant, HorseVariant.black);
    await tapVisible(tester, find.text('Dragon • 250 coins'));
    expect(game.ownedPurchases, contains(FarmItem.dragon));
    expect(find.text('Dragon • Owned'), findsOneWidget);
    await helpers.closePanel(tester);

    game.onHorseTapped(original);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tapVisible(tester, find.byKey(const ValueKey('breeding-partner')));
    await tapVisible(tester, find.text(game.horses.last.horse.name).last);
    await tapVisible(tester, find.text('Breed a foal (40 coins)'));
    expect(game.horses.length, 3);
    expect(game.horses.last.horse.parentIds, contains(original.id));
    expect(game.horses.last.horse.style, HorseStyle.spotted);
    expect(find.textContaining('unlocked for all your horses'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Spotted'));
    expect(original.horse.style, HorseStyle.spotted);
    await helpers.closePanel(tester);

    // Exercise every unlocked-style renderer and all purchased scenery.
    game.ownedPurchases = FarmItem.values.toSet();
    for (final style in HorseStyle.values) {
      original.horse = original.horse.copyWith(style: style);
      game.update(.1);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
  });
}
