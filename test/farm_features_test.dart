import 'package:flappy_bird/domain/animal.dart';
import 'package:flappy_bird/domain/game_state.dart';
import 'package:flappy_bird/domain/horse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starter farm includes all six kinds and preserves Biscuit feeding', () {
    final state = initialFarmState();
    expect(
      state.animals.values.map((a) => a.kind).toSet(),
      AnimalKind.values.toSet(),
    );
    expect(state.horses.length, 1);
    expect(feedAnimal(state, 'biscuit').inventory.food, 2);
    expect(state.animals['biscuit']!.needs.hunger, 45);
  });

  for (final kind in AnimalKind.values) {
    for (final variant in AnimalVariant.values) {
      test('buy and feed ${variant.name} ${kind.name}', () {
        final original = initialFarmState();
        final animal = Animal(
          id: 'new',
          name: 'New friend',
          kind: kind,
          variant: variant,
          needs: const AnimalNeeds(hunger: 90, happiness: 98),
        );
        final bought = buyAnimal(original, animal);
        expect(bought.coins, original.coins - kind.price);
        expect(bought.animals['new']!.kind, kind);
        expect(bought.animals['new']!.variant, variant);
        final fed = feedAnimal(bought, 'new');
        expect(fed.animals['new']!.needs.hunger, 100);
        expect(fed.animals['new']!.needs.happiness, 100);
        expect(fed.animals['new']!.variant, variant);
        expect(fed.inventory.food, 2);
        expect(original.animals.containsKey('new'), isFalse);
        expect(buyAnimal(bought, animal), same(bought));
        final poor = original.copyWith(coins: kind.price - 1);
        expect(buyAnimal(poor, animal), same(poor));
      });
    }
  }

  test('five variants are available for every kind including horses', () {
    expect(AnimalVariant.values.length, 5);
    expect(HorseVariant.values.length, 5);
    for (final variant in HorseVariant.values) {
      final result = buyHorse(
        initialFarmState(),
        Horse(id: 'new', name: 'Horse', variant: variant),
      );
      expect(result.horses['new']!.variant, variant);
      expect(result.coins, 50);
    }
  });

  for (final saddle in SaddleType.values) {
    test('${saddle.name} saddle purchases, equips and unlocks riding', () {
      final original = initialFarmState();
      expect(mountHorse(original, 'horse-1'), same(original));
      final bought = buySaddle(original, 'horse-1', saddle: saddle);
      expect(bought.coins, 100 - saddle.price);
      expect(bought.horses['horse-1']!.saddle, saddle);
      expect(bought.horses['horse-1']!.ownedSaddles, contains(saddle));
      expect(original.horses['horse-1']!.hasSaddle, isFalse);
      expect(buySaddle(bought, 'horse-1', saddle: saddle), same(bought));
      final riding = mountHorse(bought, 'horse-1');
      expect(riding.riddenHorseId, 'horse-1');
      expect(riding.coins, bought.coins);
      expect(dismountHorse(riding).riddenHorseId, isNull);
      expect(dismountHorse(riding).horses['horse-1']!.saddle, saddle);
      final poor = original.copyWith(coins: saddle.price - 1);
      expect(buySaddle(poor, 'horse-1', saddle: saddle), same(poor));
    });
  }

  test('owned saddles can be swapped without paying twice', () {
    var state = initialFarmState().copyWith(coins: 500);
    state = buySaddle(state, 'horse-1', saddle: SaddleType.western);
    state = buySaddle(state, 'horse-1', saddle: SaddleType.royal);
    final equipped = equipSaddle(state, 'horse-1', SaddleType.western);
    expect(
      equipped.coins,
      500 - SaddleType.western.price - SaddleType.royal.price,
    );
    expect(equipped.horses['horse-1']!.saddle, SaddleType.western);
    expect(equipped.horses['horse-1']!.ownedSaddles.length, 2);
    expect(equipSaddle(equipped, 'horse-1', SaddleType.racing), same(equipped));
  });

  test('invalid IDs and attempts to switch mounts fail safely', () {
    final original = initialFarmState();
    expect(mountHorse(original, 'missing'), same(original));
    expect(buySaddle(original, 'missing'), same(original));
    expect(
      equipSaddle(original, 'missing', SaddleType.classic),
      same(original),
    );
    expect(petAnimal(original, 'missing'), same(original));
    expect(petHorse(original, 'missing'), same(original));
    expect(feedAnimal(original, 'missing'), same(original));
    var state = buyHorse(
      original.copyWith(coins: 500),
      const Horse(id: 'second', name: 'Second', variant: HorseVariant.black),
    );
    state = buySaddle(buySaddle(state, 'horse-1'), 'second');
    state = mountHorse(state, 'horse-1');
    expect(mountHorse(state, 'second'), same(state));
    expect(mountHorse(dismountHorse(state), 'second').riddenHorseId, 'second');
  });

  test('petting earns coins and keeps animal identity and coat', () {
    final state = initialFarmState();
    final petted = petAnimal(state, 'donkey-1');
    expect(petted.coins, 110);
    expect(
      petted.animals['donkey-1']!.variant,
      state.animals['donkey-1']!.variant,
    );
    expect(petted.animals['donkey-1']!.needs.happiness, 75);
  });
}
