enum HorseVariant { chestnut, palomino, dapple, black, grey }

enum SaddleType { classic, western, racing, royal, trail }

extension SaddleDetails on SaddleType {
  int get price => switch (this) {
    SaddleType.classic => 30,
    SaddleType.western => 45,
    SaddleType.racing => 55,
    SaddleType.royal => 75,
    SaddleType.trail => 40,
  };
}

class Horse {
  const Horse({
    required this.id,
    required this.name,
    required this.variant,
    this.saddle,
    this.ownedSaddles = const <SaddleType>{},
    this.decorations = const <String>{},
  });

  final String id;
  final String name;
  final HorseVariant variant;
  final SaddleType? saddle;
  final Set<SaddleType> ownedSaddles;
  bool get hasSaddle => saddle != null;
  final Set<String> decorations;

  Horse copyWith({
    SaddleType? saddle,
    Set<SaddleType>? ownedSaddles,
    Set<String>? decorations,
  }) => Horse(
    id: id,
    name: name,
    variant: variant,
    saddle: saddle ?? this.saddle,
    ownedSaddles: ownedSaddles ?? this.ownedSaddles,
    decorations: decorations ?? this.decorations,
  );
}
