enum AnimalKind { sheep, goat, cow, chicken, donkey }

enum AnimalVariant { ivory, brown, black, spotted, grey }

extension AnimalKindDetails on AnimalKind {
  int get price => switch (this) {
    AnimalKind.sheep => 30,
    AnimalKind.goat => 35,
    AnimalKind.cow => 60,
    AnimalKind.chicken => 15,
    AnimalKind.donkey => 45,
  };
}

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
  const Animal({
    required this.id,
    required this.name,
    required this.needs,
    this.kind = AnimalKind.sheep,
    this.variant = AnimalVariant.ivory,
  });
  final String id;
  final String name;
  final AnimalNeeds needs;
  final AnimalKind kind;
  final AnimalVariant variant;
  Animal copyWith({AnimalNeeds? needs}) => Animal(
    id: id,
    name: name,
    kind: kind,
    variant: variant,
    needs: needs ?? this.needs,
  );
}
