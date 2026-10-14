import 'package:flappy_bird/domain/animal.dart';
import 'package:flappy_bird/domain/game_state.dart';
import 'package:flappy_bird/domain/inventory.dart';
import 'package:flutter_test/flutter_test.dart';

GameState sample({int food = 3}) => GameState(
      animals: {'a1': const Animal(id: 'a1', name: 'Biscuit', needs: AnimalNeeds(hunger: 40, happiness: 50))},
      inventory: Inventory(food: food),
    );

void main() {
  test('feeding consumes one food item', () => expect(feedAnimal(sample(), 'a1').inventory.food, 2));
  test('feeding improves hunger', () => expect(feedAnimal(sample(), 'a1').animals['a1']!.needs.hunger, 65));
  test('feeding fails safely when no food remains', () {
    final result = feedAnimal(sample(food: 0), 'a1');
    expect(result.inventory.food, 0);
    expect(result.animals['a1']!.needs.hunger, 40);
  });
}
