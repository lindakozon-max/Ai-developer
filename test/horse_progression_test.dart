import 'package:flappy_bird/domain/farm_item.dart';
import 'package:flappy_bird/domain/game_state.dart';
import 'package:flappy_bird/domain/horse.dart';
import 'package:flutter_test/flutter_test.dart';

GameState parents() => buyHorse(
  initialFarmState().copyWith(coins: 1000),
  const Horse(
    id: 'horse-2',
    name: 'Friesian',
    variant: HorseVariant.black,
    breed: HorseBreed.friesian,
  ),
);

void main() {
  test('Friesians cost 120 while ordinary horses retain their price', () {
    const friesian = Horse(
      id: 'friesian',
      name: 'Night',
      variant: HorseVariant.black,
      breed: HorseBreed.friesian,
    );
    expect(friesian.marketPrice, 120);
    final original = initialFarmState();
    expect(buyHorse(original, friesian), same(original));
    final bought = buyHorse(original.copyWith(coins: 120), friesian);
    expect(bought.coins, 0);
    expect(bought.horses['friesian']!.breed, HorseBreed.friesian);
    expect(buyHorse(bought, friesian), same(bought));
    expect(buyHorse(original, friesian, price: -1), same(original));
  });

  test('breeding inherits seeded genetics and unlocks a new style', () {
    final original = parents();
    final bred = breedHorses(original, 'horse-1', 'horse-2', seed: 42);
    final repeated = breedHorses(original, 'horse-1', 'horse-2', seed: 42);
    final foal = bred.horses['horse-3']!;
    expect(bred.coins, original.coins - 40);
    expect(bred.breedCount, 1);
    expect(foal.variant, repeated.horses['horse-3']!.variant);
    expect(foal.breed, repeated.horses['horse-3']!.breed);
    expect(foal.parentIds, ['horse-1', 'horse-2']);
    expect(foal.style, HorseStyle.spotted);
    expect(bred.unlockedHorseStyles, {HorseStyle.natural, HorseStyle.spotted});
    expect(foal.hasSaddle, isFalse);
    expect(original.horses.length, 2);
    expect(original.unlockedHorseStyles, {HorseStyle.natural});
  });

  test(
    'breeding rejects invalid parents, insufficient coins and mounted parents',
    () {
      final state = parents();
      expect(breedHorses(state, 'horse-1', 'missing', seed: 1), same(state));
      expect(breedHorses(state, 'missing', 'horse-1', seed: 1), same(state));
      expect(breedHorses(state, 'horse-1', 'horse-1', seed: 1), same(state));
      final poor = state.copyWith(coins: 39);
      expect(breedHorses(poor, 'horse-1', 'horse-2', seed: 1), same(poor));
      for (final id in ['horse-1', 'horse-2']) {
        final riding = mountHorse(buySaddle(state, id), id);
        expect(
          breedHorses(riding, 'horse-1', 'horse-2', seed: 1),
          same(riding),
        );
      }
    },
  );

  test('all styles unlock in order and remain equipped through horse care', () {
    var state = parents();
    for (final expected in HorseStyle.values.skip(1)) {
      state = breedHorses(state, 'horse-1', 'horse-2', seed: 12);
      expect(state.horses.values.last.style, expected);
      expect(state.unlockedHorseStyles, contains(expected));
    }
    final allUnlocked = state;
    state = breedHorses(state, 'horse-1', 'horse-2', seed: 12);
    expect(state.unlockedHorseStyles, HorseStyle.values.toSet());
    expect(state.horses.values.last.style, isIn(state.unlockedHorseStyles));
    state = equipHorseStyle(state, 'horse-2', HorseStyle.celestial);
    state = buyDecoration(buySaddle(state, 'horse-2'), 'horse-2', 'flower');
    expect(state.horses['horse-2']!.style, HorseStyle.celestial);
    expect(state.horses['horse-2']!.breed, HorseBreed.friesian);
    expect(allUnlocked.breedCount, 5);
  });

  test(
    'locked styles cannot be equipped or bought and offspring IDs never collide',
    () {
      final original = parents();
      expect(
        equipHorseStyle(original, 'horse-1', HorseStyle.rainbow),
        same(original),
      );
      expect(
        equipHorseStyle(original, 'missing', HorseStyle.natural),
        same(original),
      );
      expect(
        buyHorse(
          original,
          const Horse(
            id: 'locked',
            name: 'Locked',
            variant: HorseVariant.black,
            style: HorseStyle.rainbow,
          ),
        ),
        same(original),
      );
      final withGap = buyHorse(
        original,
        const Horse(
          id: 'horse-4',
          name: 'Reserved',
          variant: HorseVariant.grey,
        ),
      );
      final bred = breedHorses(withGap, 'horse-1', 'horse-2', seed: 9);
      expect(bred.horses['horse-4']!.name, 'Reserved');
      expect(bred.horses['horse-5']!.parentIds, ['horse-1', 'horse-2']);
    },
  );

  for (final item in FarmItem.values) {
    test(
      '${item.name} purchases charge once and reject insufficient coins',
      () {
        final original = initialFarmState().copyWith(coins: item.price);
        final bought = buyFarmItem(original, item);
        expect(bought.coins, 0);
        expect(bought.ownedPurchases, contains(item));
        expect(original.ownedPurchases, isEmpty);
        expect(buyFarmItem(bought, item), same(bought));
        final poor = original.copyWith(coins: item.price - 1);
        expect(buyFarmItem(poor, item), same(poor));
        expect(petHorse(bought, 'horse-1').ownedPurchases, contains(item));
      },
    );
  }
}
