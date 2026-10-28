import 'dart:math';

import 'animal.dart';
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
  });
  final Map<String, Animal> animals;
  final Inventory inventory;
  final Map<String, Horse> horses;
  final int coins;
  final String? riddenHorseId;
  final Set<HorseStyle> unlockedHorseStyles;
  final int breedCount;
  final Set<FarmItem> ownedPurchases;
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
  }) => GameState(
    animals: animals ?? this.animals,
    inventory: inventory ?? this.inventory,
    horses: horses ?? this.horses,
    coins: coins ?? this.coins,
    riddenHorseId: dismount ? null : riddenHorseId ?? this.riddenHorseId,
    unlockedHorseStyles: unlockedHorseStyles ?? this.unlockedHorseStyles,
    breedCount: breedCount ?? this.breedCount,
    ownedPurchases: ownedPurchases ?? this.ownedPurchases,
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
  var suffix = state.horses.length + 1;
  while (state.horses.containsKey('horse-$suffix')) {
    suffix++;
  }
  final foal = Horse(
    id: 'horse-$suffix',
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
  if (horse == null || !horse.hasSaddle || state.riddenHorseId != null) {
    return state;
  }
  return state.copyWith(riddenHorseId: horseId);
}

GameState dismountHorse(GameState state) => state.copyWith(dismount: true);

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
