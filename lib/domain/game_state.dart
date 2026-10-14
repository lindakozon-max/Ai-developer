import 'animal.dart';
import 'inventory.dart';

class GameState {
  const GameState({required this.animals, required this.inventory});
  final Map<String, Animal> animals;
  final Inventory inventory;
  GameState copyWith({Map<String, Animal>? animals, Inventory? inventory}) => GameState(
        animals: animals ?? this.animals,
        inventory: inventory ?? this.inventory,
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
