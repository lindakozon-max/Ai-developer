class AnimalNeeds {
  const AnimalNeeds({required this.hunger, required this.happiness});
  final int hunger;
  final int happiness;
  AnimalNeeds copyWith({int? hunger, int? happiness}) => AnimalNeeds(
        hunger: (hunger ?? this.hunger).clamp(0, 100),
        happiness: (happiness ?? this.happiness).clamp(0, 100),
      );
}

class Animal {
  const Animal({required this.id, required this.name, required this.needs});
  final String id;
  final String name;
  final AnimalNeeds needs;
  Animal copyWith({AnimalNeeds? needs}) => Animal(id: id, name: name, needs: needs ?? this.needs);
}
