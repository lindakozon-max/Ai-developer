import 'package:flappy_bird/domain/animal.dart';
import 'package:flappy_bird/domain/game_state.dart';
import 'package:flappy_bird/domain/inventory.dart';
import 'package:flappy_bird/domain/horse.dart';
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
  test('petting a horse rewards coins', () {
    final state = sample().copyWith(horses: {
      'h1': const Horse(id: 'h1', name: 'Chestnut', variant: HorseVariant.chestnut),
    });
    expect(petHorse(state, 'h1').coins, 110);
  });
  test('horse purchases add a horse and spend coins', () {
    final result = buyHorse(
      sample(),
      const Horse(id: 'h1', name: 'Palomino', variant: HorseVariant.palomino),
    );
    expect(result.horses['h1']!.variant, HorseVariant.palomino);
    expect(result.coins, 50);
  });
}
