import 'dart:math';

import 'animal.dart';
import 'dragon.dart';
import 'farm_item.dart';
import 'horse.dart';
import 'inventory.dart';

class GameState {
  const GameState({
    required this.animals,
    required this.inventory,
    this.horses = const {},
    this.coins = 100,
    this.riddenHorseId,
    this.unlockedHorseStyles = const {HorseStyle.natural},
    this.breedCount = 0,
    this.ownedPurchases = const {},
    this.dragons = const {},
    this.riddenDragonId,
    this.dragonBreedCount = 0,
  });
  final Map<String, Animal> animals;
  final Inventory inventory;
  final Map<String, Horse> horses;
  final int coins;
  final String? riddenHorseId;
  final Set<HorseStyle> unlockedHorseStyles;
  final int breedCount;
  final Set<FarmItem> ownedPurchases;
  final Map<String, Dragon> dragons;
  final String? riddenDragonId;
  final int dragonBreedCount;
  GameState copyWith({
    Map<String, Animal>? animals,
    Inventory? inventory,
    Map<String, Horse>? horses,
    int? coins,
    String? riddenHorseId,
    bool dismount = false,
    Set<HorseStyle>? unlockedHorseStyles,
    int? breedCount,
    Set<FarmItem>? ownedPurchases,
    Map<String, Dragon>? dragons,
    String? riddenDragonId,
    bool clearDragonMount = false,
    int? dragonBreedCount,
  }) => GameState(
    animals: animals ?? this.animals,
    inventory: inventory ?? this.inventory,
    horses: horses ?? this.horses,
    coins: coins ?? this.coins,
    riddenHorseId: dismount ? null : riddenHorseId ?? this.riddenHorseId,
    unlockedHorseStyles: unlockedHorseStyles ?? this.unlockedHorseStyles,
    breedCount: breedCount ?? this.breedCount,
    ownedPurchases: ownedPurchases ?? this.ownedPurchases,
    dragons: dragons ?? this.dragons,
    riddenDragonId: clearDragonMount
        ? null
        : riddenDragonId ?? this.riddenDragonId,
    dragonBreedCount: dragonBreedCount ?? this.dragonBreedCount,
  );
}

GameState petHorse(GameState state, String horseId) {
  if (!state.horses.containsKey(horseId)) return state;
  return state.copyWith(coins: state.coins + 10);
}

GameState buyHorse(GameState state, Horse horse, {int? price}) {
  final cost = price ?? horse.marketPrice;
  if (cost < 0 ||
      state.coins < cost ||
      state.horses.containsKey(horse.id) ||
      !state.unlockedHorseStyles.contains(horse.style)) {
    return state;
  }
  return state.copyWith(
    horses: {...state.horses, horse.id: horse},
    coins: state.coins - cost,
  );
}

GameState buyFarmItem(GameState state, FarmItem item) {
  if (state.ownedPurchases.contains(item) || state.coins < item.price) {
    return state;
  }
  return state.copyWith(
    coins: state.coins - item.price,
    ownedPurchases: {...state.ownedPurchases, item},
    dragons: item == FarmItem.dragon
        ? {
            ...state.dragons,
            nextDragonId(state): Dragon(id: nextDragonId(state), name: 'Ember'),
          }
        : state.dragons,
  );
}

GameState equipHorseStyle(GameState state, String horseId, HorseStyle style) {
  final horse = state.horses[horseId];
  if (horse == null || !state.unlockedHorseStyles.contains(style)) return state;
  return state.copyWith(
    horses: {
      ...state.horses,
      horseId: horse.copyWith(style: style),
    },
  );
}

/// Successful breeding unlocks the next style. Genetics depend only on the seed
/// and parent order, never on frame timing or temporary horse equipment.
GameState breedHorses(
  GameState state,
  String firstId,
  String secondId, {
  required int seed,
}) {
  final first = state.horses[firstId];
  final second = state.horses[secondId];
  if (first == null ||
      second == null ||
      firstId == secondId ||
      state.coins < 40 ||
      state.riddenHorseId == firstId ||
      state.riddenHorseId == secondId) {
    return state;
  }
  final random = Random(seed);
  HorseStyle? nextStyle;
  for (final style in HorseStyle.values) {
    if (!state.unlockedHorseStyles.contains(style)) {
      nextStyle = style;
      break;
    }
  }
  final unlocked = {...state.unlockedHorseStyles, ?nextStyle};
  final styles = HorseStyle.values.where(unlocked.contains).toList();
  final style = nextStyle ?? styles[random.nextInt(styles.length)];
  final id = nextHorseId(state);
  final suffix = id.substring('horse-'.length);
  final foal = Horse(
    id: id,
    name: '${style.name} foal $suffix',
    variant: random.nextBool() ? first.variant : second.variant,
    breed: random.nextBool() ? first.breed : second.breed,
    style: style,
    parentIds: List.unmodifiable([firstId, secondId]),
  );
  return state.copyWith(
    coins: state.coins - 40,
    horses: {...state.horses, foal.id: foal},
    unlockedHorseStyles: unlocked,
    breedCount: state.breedCount + 1,
  );
}

GameState buySaddle(
  GameState state,
  String horseId, {
  SaddleType saddle = SaddleType.classic,
}) {
  final horse = state.horses[horseId];
  if (horse == null ||
      horse.ownedSaddles.contains(saddle) ||
      state.coins < saddle.price) {
    return state;
  }
  return state.copyWith(
    horses: {
      ...state.horses,
      horseId: horse.copyWith(
        saddle: saddle,
        ownedSaddles: {...horse.ownedSaddles, saddle},
      ),
    },
    coins: state.coins - saddle.price,
  );
}

GameState equipSaddle(GameState state, String horseId, SaddleType saddle) {
  final horse = state.horses[horseId];
  if (horse == null || !horse.ownedSaddles.contains(saddle)) return state;
  return state.copyWith(
    horses: {
      ...state.horses,
      horseId: horse.copyWith(saddle: saddle),
    },
  );
}

GameState mountHorse(GameState state, String horseId) {
  final horse = state.horses[horseId];
  if (horse == null ||
      !horse.hasSaddle ||
      state.riddenHorseId != null ||
      state.riddenDragonId != null) {
    return state;
  }
  return state.copyWith(riddenHorseId: horseId);
}

GameState dismountHorse(GameState state) => state.copyWith(dismount: true);

String _nextId(String prefix, Iterable<String> ids) {
  var highest = 0;
  for (final id in ids) {
    if (!id.startsWith('$prefix-')) continue;
    final suffix = int.tryParse(id.substring(prefix.length + 1));
    if (suffix != null && suffix > highest) highest = suffix;
  }
  return '$prefix-${highest + 1}';
}

String nextAnimalId(GameState state) => _nextId('animal', state.animals.keys);
String nextHorseId(GameState state) => _nextId('horse', [
  ...state.horses.keys,
  ...state.horses.values.expand((horse) => horse.parentIds),
]);
String nextDragonId(GameState state) => _nextId('dragon', [
  ...state.dragons.keys,
  ...state.dragons.values.expand((dragon) => dragon.parentIds),
]);

GameState removeAnimal(GameState state, String animalId) {
  if (!state.animals.containsKey(animalId)) return state;
  return state.copyWith(animals: {...state.animals}..remove(animalId));
}

GameState removeHorse(GameState state, String horseId) {
  if (!state.horses.containsKey(horseId)) return state;
  return state.copyWith(
    horses: {...state.horses}..remove(horseId),
    dismount: state.riddenHorseId == horseId,
  );
}

GameState removeDragon(GameState state, String dragonId) {
  if (!state.dragons.containsKey(dragonId)) return state;
  final dragons = {...state.dragons}..remove(dragonId);
  return state.copyWith(
    dragons: dragons,
    clearDragonMount: state.riddenDragonId == dragonId,
    ownedPurchases: dragons.isEmpty
        ? ({...state.ownedPurchases}..remove(FarmItem.dragon))
        : state.ownedPurchases,
  );
}

GameState buyDragon(GameState state, Dragon dragon) {
  if (state.dragons.containsKey(dragon.id) ||
      state.coins < dragon.marketPrice ||
      dragon.elements.isEmpty ||
      dragon.elements.length > 2) {
    return state;
  }
  return state.copyWith(
    dragons: {...state.dragons, dragon.id: dragon},
    coins: state.coins - dragon.marketPrice,
  );
}

GameState petDragon(GameState state, String dragonId) {
  if (!state.dragons.containsKey(dragonId)) return state;
  return state.copyWith(coins: state.coins + 10);
}

GameState buyDragonSaddle(
  GameState state,
  String dragonId, {
  SaddleType saddle = SaddleType.classic,
}) {
  final dragon = state.dragons[dragonId];
  if (dragon == null ||
      dragon.ownedSaddles.contains(saddle) ||
      state.coins < saddle.price) {
    return state;
  }
  return state.copyWith(
    dragons: {
      ...state.dragons,
      dragonId: dragon.copyWith(
        saddle: saddle,
        ownedSaddles: {...dragon.ownedSaddles, saddle},
      ),
    },
    coins: state.coins - saddle.price,
  );
}

GameState equipDragonSaddle(
  GameState state,
  String dragonId,
  SaddleType saddle,
) {
  final dragon = state.dragons[dragonId];
  if (dragon == null || !dragon.ownedSaddles.contains(saddle)) return state;
  return state.copyWith(
    dragons: {
      ...state.dragons,
      dragonId: dragon.copyWith(saddle: saddle),
    },
  );
}

GameState mountDragon(GameState state, String dragonId) {
  final dragon = state.dragons[dragonId];
  if (dragon == null ||
      !dragon.hasSaddle ||
      state.riddenHorseId != null ||
      state.riddenDragonId != null) {
    return state;
  }
  return state.copyWith(riddenDragonId: dragonId);
}

GameState dismountDragon(GameState state) =>
    state.copyWith(clearDragonMount: true);

/// Each parent contributes one element, selected from a stable enum order.
GameState breedDragons(
  GameState state,
  String firstId,
  String secondId, {
  required int seed,
}) {
  final first = state.dragons[firstId];
  final second = state.dragons[secondId];
  if (first == null ||
      second == null ||
      firstId == secondId ||
      first.elements.isEmpty ||
      second.elements.isEmpty ||
      state.coins < 80 ||
      state.riddenDragonId == firstId ||
      state.riddenDragonId == secondId) {
    return state;
  }
  final random = Random(seed);
  final firstElements = DragonElement.values
      .where(first.elements.contains)
      .toList();
  final secondElements = DragonElement.values
      .where(second.elements.contains)
      .toList();
  final elements = Set<DragonElement>.unmodifiable({
    firstElements[random.nextInt(firstElements.length)],
    secondElements[random.nextInt(secondElements.length)],
  });
  final id = nextDragonId(state);
  final description = DragonElement.values
      .where(elements.contains)
      .map((element) => element.name)
      .join('–');
  final hatchling = Dragon(
    id: id,
    name: '$description hatchling ${state.dragonBreedCount + 1}',
    elements: elements,
    parentIds: List.unmodifiable([firstId, secondId]),
  );
  return state.copyWith(
    dragons: {...state.dragons, id: hatchling},
    coins: state.coins - 80,
    dragonBreedCount: state.dragonBreedCount + 1,
  );
}

GameState buyAnimal(GameState state, Animal animal) {
  if (state.coins < animal.kind.price || state.animals.containsKey(animal.id)) {
    return state;
  }
  return state.copyWith(
    animals: {...state.animals, animal.id: animal},
    coins: state.coins - animal.kind.price,
  );
}

GameState petAnimal(GameState state, String animalId) {
  final animal = state.animals[animalId];
  if (animal == null) return state;
  return state.copyWith(
    coins: state.coins + 10,
    animals: {
      ...state.animals,
      animalId: animal.copyWith(
        needs: animal.needs.copyWith(happiness: animal.needs.happiness + 5),
      ),
    },
  );
}

GameState buyDecoration(
  GameState state,
  String horseId,
  String decoration, {
  int price = 20,
}) {
  final horse = state.horses[horseId];
  if (price < 0 ||
      horse == null ||
      horse.decorations.contains(decoration) ||
      state.coins < price) {
    return state;
  }
  return state.copyWith(
    horses: {
      ...state.horses,
      horseId: horse.copyWith(decorations: {...horse.decorations, decoration}),
    },
    coins: state.coins - price,
  );
}

GameState buyFood(GameState state, FoodType food, {int quantity = 1}) {
  if (quantity <= 0 || state.coins < food.price * quantity) return state;
  return state.copyWith(
    coins: state.coins - food.price * quantity,
    inventory: state.inventory.withCount(
      food,
      state.inventory.count(food) + quantity,
    ),
  );
}

GameState playWithAnimal(
  GameState state,
  String animalId, {
  AnimalToy toy = AnimalToy.ball,
}) {
  final animal = state.animals[animalId];
  if (animal == null) return state;
  return state.copyWith(
    animals: {
      ...state.animals,
      animalId: animal.copyWith(
        needs: animal.needs.copyWith(happiness: animal.needs.happiness + 12),
      ),
    },
  );
}

GameState feedAnimal(
  GameState state,
  String animalId, {
  FoodType food = FoodType.pellets,
}) {
  final animal = state.animals[animalId];
  if (animal == null || state.inventory.count(food) <= 0) return state;
  return state.copyWith(
    animals: {
      ...state.animals,
      animalId: animal.copyWith(
        needs: animal.needs.copyWith(
          hunger: animal.needs.hunger + food.nutrition,
          happiness:
              animal.needs.happiness +
              (animal.kind.favoriteFood == food ? 10 : 5),
        ),
      ),
    },
    inventory: state.inventory.withCount(food, state.inventory.count(food) - 1),
  );
}

GameState initialFarmState() => GameState(
  animals: {
    'biscuit': const Animal(
      id: 'biscuit',
      name: 'Biscuit',
      needs: AnimalNeeds(hunger: 45, happiness: 70),
    ),
    for (final kind in AnimalKind.values.where(
      (kind) => kind != AnimalKind.sheep,
    ))
      '${kind.name}-1': Animal(
        id: '${kind.name}-1',
        name: '${kind.name[0].toUpperCase()}${kind.name.substring(1)}',
        kind: kind,
        variant: AnimalVariant.values[kind.index],
        needs: const AnimalNeeds(hunger: 45, happiness: 70),
      ),
  },
  inventory: const Inventory(food: 3),
  horses: {
    'horse-1': const Horse(
      id: 'horse-1',
      name: 'Chestnut',
      variant: HorseVariant.chestnut,
    ),
  },
);
