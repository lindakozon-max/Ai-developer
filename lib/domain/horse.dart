enum HorseVariant { chestnut, palomino, dapple, black, grey }

enum HorseBreed { farm, friesian }

enum HorseStyle { natural, spotted, golden, midnight, rainbow, celestial }

enum SaddleType {
  classic,
  western,
  racing,
  royal,
  trail,
  dressage,
  endurance,
  jousting,
  sky,
  ember,
}

extension SaddleDetails on SaddleType {
  int get price => switch (this) {
    SaddleType.classic => 30,
    SaddleType.western => 45,
    SaddleType.racing => 55,
    SaddleType.royal => 75,
    SaddleType.trail => 40,
    SaddleType.dressage => 60,
    SaddleType.endurance => 65,
    SaddleType.jousting => 90,
    SaddleType.sky => 85,
    SaddleType.ember => 95,
  };
}

class Horse {
  const Horse({
    required this.id,
    required this.name,
    required this.variant,
    this.breed = HorseBreed.farm,
    this.style = HorseStyle.natural,
    this.parentIds = const [],
    this.saddle,
    this.ownedSaddles = const <SaddleType>{},
    this.decorations = const <String>{},
  });

  final String id;
  final String name;
  final HorseVariant variant;
  final HorseBreed breed;
  final HorseStyle style;
  final List<String> parentIds;
  int get marketPrice => breed == HorseBreed.friesian ? 120 : 50;
  final SaddleType? saddle;
  final Set<SaddleType> ownedSaddles;
  bool get hasSaddle => saddle != null;
  final Set<String> decorations;

  Horse copyWith({
    HorseStyle? style,
    SaddleType? saddle,
    Set<SaddleType>? ownedSaddles,
    Set<String>? decorations,
  }) => Horse(
    id: id,
    name: name,
    variant: variant,
    breed: breed,
    style: style ?? this.style,
    parentIds: parentIds,
    saddle: saddle ?? this.saddle,
    ownedSaddles: ownedSaddles ?? this.ownedSaddles,
    decorations: decorations ?? this.decorations,
  );
}
