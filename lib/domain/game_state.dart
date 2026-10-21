import 'animal.dart';
import 'horse.dart';
import 'inventory.dart';

class GameState {
  const GameState({
    required this.animals,
    required this.inventory,
    this.horses = const {},
    this.coins = 100,
  });
  final Map<String, Animal> animals;
  final Inventory inventory;
  final Map<String, Horse> horses;
  final int coins;
  GameState copyWith({
    Map<String, Animal>? animals,
    Inventory? inventory,
    Map<String, Horse>? horses,
    int? coins,
  }) => GameState(
        animals: animals ?? this.animals,
        inventory: inventory ?? this.inventory,
        horses: horses ?? this.horses,
        coins: coins ?? this.coins,
      );
}

GameState petHorse(GameState state, String horseId) {
  if (!state.horses.containsKey(horseId)) return state;
  return state.copyWith(coins: state.coins + 10);
}

GameState buyHorse(GameState state, Horse horse, {int price = 50}) {
  if (state.coins < price || state.horses.containsKey(horse.id)) return state;
  return state.copyWith(
    horses: {...state.horses, horse.id: horse},
    coins: state.coins - price,
  );
}

GameState buySaddle(GameState state, String horseId, {int price = 30}) {
  final horse = state.horses[horseId];
  if (horse == null || horse.hasSaddle || state.coins < price) return state;
  return state.copyWith(
    horses: {...state.horses, horseId: horse.copyWith(hasSaddle: true)},
    coins: state.coins - price,
  );
}

GameState buyDecoration(GameState state, String horseId, String decoration, {int price = 20}) {
  final horse = state.horses[horseId];
  if (horse == null || horse.decorations.contains(decoration) || state.coins < price) return state;
  return state.copyWith(
    horses: {
      ...state.horses,
      horseId: horse.copyWith(decorations: {...horse.decorations, decoration}),
    },
    coins: state.coins - price,
  );
}

GameState feedAnimal(GameState state, String animalId) {
  final animal = state.animals[animalId];
  if (animal == null || state.inventory.food == 0) return state;
  return state.copyWith(
    animals: {
      ...state.animals,
      animalId: animal.copyWith(needs: animal.needs.copyWith(
        hunger: animal.needs.hunger + 25,
        happiness: animal.needs.happiness + 5,
      )),
    },
    inventory: state.inventory.copyWith(food: state.inventory.food - 1),
  );
}
