import 'package:flappy_bird/domain/animal.dart';
import 'package:flappy_bird/domain/game_state.dart';
import 'package:flappy_bird/domain/inventory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final food in FoodType.values) {
    test('buy and feed ${food.name} without consuming another food', () {
      final original = initialFarmState();
      final bought = buyFood(original, food, quantity: 2);
      expect(bought.coins, original.coins - food.price * 2);
      expect(bought.inventory.count(food), original.inventory.count(food) + 2);
      final fed = feedAnimal(bought, 'biscuit', food: food);
      expect(fed.inventory.count(food), bought.inventory.count(food) - 1);
      expect(fed.animals['biscuit']!.needs.hunger, 45 + food.nutrition);
      for (final other in FoodType.values.where((item) => item != food)) {
        expect(fed.inventory.count(other), original.inventory.count(other));
      }
      expect(original.coins, 100);
      expect(original.animals['biscuit']!.needs.hunger, 45);
    });
  }

  test('food purchases reject invalid quantities and insufficient coins', () {
    final state = initialFarmState();
    expect(buyFood(state, FoodType.apples, quantity: 0), same(state));
    expect(buyFood(state, FoodType.apples, quantity: -1), same(state));
    expect(buyFood(state, FoodType.apples, quantity: 100), same(state));
    final poor = state.copyWith(coins: 0);
    expect(buyFood(poor, FoodType.hay), same(poor));
  });

  test('empty selected food does not consume available pellets', () {
    final state = initialFarmState();
    expect(feedAnimal(state, 'biscuit', food: FoodType.hay), same(state));
    expect(state.inventory.food, 3);
  });

  for (final kind in AnimalKind.values) {
    test('${kind.name} gains extra happiness from its favorite food', () {
      final initial = initialFarmState();
      final animal = initial.animals.values.firstWhere((a) => a.kind == kind);
      final bought = buyFood(initial, kind.favoriteFood);
      final fed = feedAnimal(bought, animal.id, food: kind.favoriteFood);
      expect(fed.animals[animal.id]!.needs.happiness, 80);
      expect(fed.animals[animal.id]!.variant, animal.variant);
    });
  }

  for (final toy in AnimalToy.values) {
    test(
      '${toy.name} play improves happiness without spending food or coins',
      () {
        final state = initialFarmState();
        final played = playWithAnimal(state, 'biscuit', toy: toy);
        expect(played.animals['biscuit']!.needs.happiness, 82);
        expect(played.animals['biscuit']!.needs.hunger, 45);
        expect(played.inventory, same(state.inventory));
        expect(played.coins, state.coins);
        expect(playWithAnimal(state, 'missing', toy: toy), same(state));
        final happy = playWithAnimal(
          playWithAnimal(played, 'biscuit'),
          'biscuit',
        );
        expect(happy.animals['biscuit']!.needs.happiness, 100);
      },
    );
  }
}
