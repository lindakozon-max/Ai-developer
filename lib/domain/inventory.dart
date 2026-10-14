class Inventory {
  const Inventory({required this.food});
  final int food;
  Inventory copyWith({int? food}) => Inventory(food: food ?? this.food);
}
