enum FoodType { pellets, hay, carrots, apples, grain, greens }

extension FoodTypeDetails on FoodType {
  int get price => switch (this) {
    FoodType.pellets => 3,
    FoodType.hay => 4,
    FoodType.carrots => 5,
    FoodType.apples => 6,
    FoodType.grain => 4,
    FoodType.greens => 4,
  };

  int get nutrition => switch (this) {
    FoodType.pellets => 25,
    FoodType.hay => 30,
    FoodType.carrots => 20,
    FoodType.apples => 20,
    FoodType.grain => 30,
    FoodType.greens => 25,
  };
}

class Inventory {
  const Inventory({required this.food, this.foods = const {}});
  final int food;
  final Map<FoodType, int> foods;

  int count(FoodType type) =>
      type == FoodType.pellets ? food : foods[type] ?? 0;

  Inventory withCount(FoodType type, int count) => type == FoodType.pellets
      ? copyWith(food: count)
      : Inventory(food: food, foods: {...foods, type: count});

  Inventory copyWith({int? food}) =>
      Inventory(food: food ?? this.food, foods: foods);
}
