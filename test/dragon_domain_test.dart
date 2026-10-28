import 'package:flappy_bird/domain/animal.dart';
import 'package:flappy_bird/domain/dragon.dart';
import 'package:flappy_bird/domain/farm_item.dart';
import 'package:flappy_bird/domain/game_state.dart';
import 'package:flappy_bird/domain/horse.dart';
import 'package:flutter_test/flutter_test.dart';

GameState dragonParents() {
  var state = initialFarmState().copyWith(coins: 2000);
  state = buyDragon(state, const Dragon(id: 'dragon-1', name: 'Ember'));
  return buyDragon(
    state,
    const Dragon(id: 'dragon-2', name: 'Frost', elements: {DragonElement.ice}),
  );
}

void main() {
  test('legacy dragon purchase creates a pet and remains one-time', () {
    final original = initialFarmState().copyWith(coins: 250);
    final bought = buyFarmItem(original, FarmItem.dragon);
    expect(bought.dragons['dragon-1']!.name, 'Ember');
    expect(bought.dragons['dragon-1']!.elements, {DragonElement.fire});
    expect(bought.coins, 0);
    expect(bought.ownedPurchases, contains(FarmItem.dragon));
    expect(buyFarmItem(bought, FarmItem.dragon), same(bought));
    expect(original.dragons, isEmpty);
    final removed = removeDragon(bought, 'dragon-1');
    expect(removed.dragons, isEmpty);
    expect(removed.ownedPurchases, isNot(contains(FarmItem.dragon)));
    expect(
      buyFarmItem(removed.copyWith(coins: 250), FarmItem.dragon).dragons.length,
      1,
    );
  });

  test('all dragon elements can be purchased and petted', () {
    for (final element in DragonElement.values) {
      final original = initialFarmState().copyWith(coins: 250);
      final dragon = Dragon(
        id: 'dragon-1',
        name: element.name,
        elements: {element},
      );
      final bought = buyDragon(original, dragon);
      expect(bought.coins, 0);
      expect(bought.dragons['dragon-1']!.elements, {element});
      expect(buyDragon(bought, dragon), same(bought));
      expect(petDragon(bought, 'dragon-1').coins, 10);
      expect(petDragon(bought, 'missing'), same(bought));
      expect(buyDragon(original.copyWith(coins: 249), dragon).dragons, isEmpty);
    }
  });

  test('hybrid market cost and invalid element sets are guarded', () {
    final original = initialFarmState().copyWith(coins: 400);
    const hybrid = Dragon(
      id: 'hybrid',
      name: 'Steam',
      elements: {DragonElement.fire, DragonElement.ice},
    );
    expect(hybrid.isHybrid, isTrue);
    expect(hybrid.marketPrice, 400);
    expect(buyDragon(original, hybrid).coins, 0);
    expect(buyDragon(original.copyWith(coins: 399), hybrid).dragons, isEmpty);
    expect(
      buyDragon(
        original,
        const Dragon(id: 'empty', name: 'Empty', elements: {}),
      ),
      same(original),
    );
    expect(
      buyDragon(
        original.copyWith(coins: 1000),
        Dragon(id: 'all', name: 'All', elements: DragonElement.values.toSet()),
      ).dragons,
      isEmpty,
    );
  });

  test(
    'crossing pure dragons produces deterministic hybrids with pedigree',
    () {
      final original = dragonParents();
      final bred = breedDragons(original, 'dragon-1', 'dragon-2', seed: 99);
      final hatchling = bred.dragons['dragon-3']!;
      expect(hatchling.elements, {DragonElement.fire, DragonElement.ice});
      expect(hatchling.isHybrid, isTrue);
      expect(hatchling.parentIds, ['dragon-1', 'dragon-2']);
      expect(hatchling.hasSaddle, isFalse);
      expect(bred.coins, original.coins - 80);
      expect(bred.dragonBreedCount, 1);
      expect(original.dragons.length, 2);
      final repeated = breedDragons(original, 'dragon-1', 'dragon-2', seed: 99);
      expect(repeated.dragons['dragon-3']!.elements, hatchling.elements);
      expect(
        () => hatchling.elements.add(DragonElement.forest),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'hybrid inheritance uses stable element order independent of set order',
    () {
      final first = dragonParents().copyWith(
        dragons: {
          'a': const Dragon(
            id: 'a',
            name: 'A',
            elements: {DragonElement.fire, DragonElement.ice},
          ),
          'b': const Dragon(
            id: 'b',
            name: 'B',
            elements: {DragonElement.forest, DragonElement.storm},
          ),
        },
      );
      final reordered = first.copyWith(
        dragons: {
          'a': const Dragon(
            id: 'a',
            name: 'A',
            elements: {DragonElement.ice, DragonElement.fire},
          ),
          'b': const Dragon(
            id: 'b',
            name: 'B',
            elements: {DragonElement.storm, DragonElement.forest},
          ),
        },
      );
      expect(
        breedDragons(first, 'a', 'b', seed: 17).dragons.values.last.elements,
        breedDragons(
          reordered,
          'a',
          'b',
          seed: 17,
        ).dragons.values.last.elements,
      );
    },
  );

  test('breeding refuses missing, same, poor and mounted parents', () {
    final original = dragonParents();
    expect(
      breedDragons(original, 'dragon-1', 'missing', seed: 1),
      same(original),
    );
    expect(
      breedDragons(original, 'dragon-1', 'dragon-1', seed: 1),
      same(original),
    );
    final poor = original.copyWith(coins: 79);
    expect(breedDragons(poor, 'dragon-1', 'dragon-2', seed: 1), same(poor));
    for (final id in original.dragons.keys) {
      final riding = mountDragon(buyDragonSaddle(original, id), id);
      expect(
        breedDragons(riding, 'dragon-1', 'dragon-2', seed: 1),
        same(riding),
      );
    }
  });

  for (final saddle in SaddleType.values) {
    test('${saddle.name} dragon saddle purchases, equips and mounts', () {
      final original = dragonParents();
      expect(mountDragon(original, 'dragon-1'), same(original));
      final equipped = buyDragonSaddle(original, 'dragon-1', saddle: saddle);
      expect(equipped.coins, original.coins - saddle.price);
      expect(equipped.dragons['dragon-1']!.saddle, saddle);
      expect(equipped.dragons['dragon-1']!.ownedSaddles, {saddle});
      expect(
        buyDragonSaddle(equipped, 'dragon-1', saddle: saddle),
        same(equipped),
      );
      final riding = mountDragon(equipped, 'dragon-1');
      expect(riding.riddenDragonId, 'dragon-1');
      expect(dismountDragon(riding).riddenDragonId, isNull);
      expect(dismountDragon(riding).dragons['dragon-1']!.saddle, saddle);
      final poor = original.copyWith(coins: saddle.price - 1);
      expect(buyDragonSaddle(poor, 'dragon-1', saddle: saddle), same(poor));
    });
  }

  test(
    'saddles can be changed without buying twice; invalid IDs fail safely',
    () {
      final original = dragonParents();
      var state = buyDragonSaddle(original, 'dragon-1', saddle: SaddleType.sky);
      state = buyDragonSaddle(state, 'dragon-1', saddle: SaddleType.ember);
      final changed = equipDragonSaddle(state, 'dragon-1', SaddleType.sky);
      expect(changed.coins, state.coins);
      expect(changed.dragons['dragon-1']!.saddle, SaddleType.sky);
      expect(
        equipDragonSaddle(changed, 'dragon-1', SaddleType.classic),
        same(changed),
      );
      expect(
        equipDragonSaddle(changed, 'missing', SaddleType.sky),
        same(changed),
      );
      expect(buyDragonSaddle(changed, 'missing'), same(changed));
      expect(mountDragon(changed, 'missing'), same(changed));
    },
  );

  test('only one horse or dragon can be ridden at a time', () {
    var state = buyDragonSaddle(dragonParents(), 'dragon-1');
    state = buySaddle(state, 'horse-1');
    final dragonRiding = mountDragon(state, 'dragon-1');
    expect(mountHorse(dragonRiding, 'horse-1'), same(dragonRiding));
    expect(mountDragon(dragonRiding, 'dragon-2'), same(dragonRiding));
    final horseRiding = mountHorse(state, 'horse-1');
    expect(mountDragon(horseRiding, 'dragon-1'), same(horseRiding));
    expect(
      mountDragon(dismountHorse(horseRiding), 'dragon-1').riddenDragonId,
      'dragon-1',
    );
  });

  test('removal preserves balance and dismounts only the removed mount', () {
    final original = dragonParents();
    final animalRemoved = removeAnimal(original, 'biscuit');
    expect(animalRemoved.animals, isNot(contains('biscuit')));
    expect(original.animals, contains('biscuit'));
    expect(animalRemoved.coins, original.coins);
    final horseRiding = mountHorse(buySaddle(original, 'horse-1'), 'horse-1');
    final horseRemoved = removeHorse(horseRiding, 'horse-1');
    expect(horseRemoved.horses, isEmpty);
    expect(horseRemoved.riddenHorseId, isNull);
    expect(horseRemoved.coins, horseRiding.coins);
    final dragonRiding = mountDragon(
      buyDragonSaddle(original, 'dragon-1'),
      'dragon-1',
    );
    expect(removeDragon(dragonRiding, 'dragon-2').riddenDragonId, 'dragon-1');
    final dragonRemoved = removeDragon(dragonRiding, 'dragon-1');
    expect(dragonRemoved.riddenDragonId, isNull);
    expect(dragonRemoved.dragons, isNot(contains('dragon-1')));
    expect(dragonRemoved.coins, dragonRiding.coins);
    expect(removeAnimal(original, 'missing'), same(original));
    expect(removeHorse(original, 'missing'), same(original));
    expect(removeDragon(original, 'missing'), same(original));
  });

  test('IDs avoid gaps and still-referenced pedigree IDs after removal', () {
    final original = dragonParents();
    final bred = breedDragons(original, 'dragon-1', 'dragon-2', seed: 1);
    final removed = removeDragon(removeDragon(bred, 'dragon-1'), 'dragon-2');
    expect(nextDragonId(removed), 'dragon-4');
    final horseParent = buyHorse(
      original,
      const Horse(id: 'horse-9', name: 'Nine', variant: HorseVariant.black),
    );
    final foalState = breedHorses(horseParent, 'horse-1', 'horse-9', seed: 4);
    expect(foalState.horses, contains('horse-10'));
    expect(nextHorseId(removeHorse(foalState, 'horse-9')), 'horse-11');
    final animals = original.copyWith(
      animals: {
        ...original.animals,
        'animal-8': const Animal(
          id: 'animal-8',
          name: 'Eight',
          needs: AnimalNeeds(hunger: 50, happiness: 50),
        ),
      },
    );
    expect(nextAnimalId(animals), 'animal-9');
  });
}
