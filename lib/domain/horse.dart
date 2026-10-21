enum HorseVariant { chestnut, palomino, dapple }

class Horse {
  const Horse({
    required this.id,
    required this.name,
    required this.variant,
    this.hasSaddle = false,
    this.decorations = const <String>{},
  });

  final String id;
  final String name;
  final HorseVariant variant;
  final bool hasSaddle;
  final Set<String> decorations;

  Horse copyWith({bool? hasSaddle, Set<String>? decorations}) => Horse(
        id: id,
        name: name,
        variant: variant,
        hasSaddle: hasSaddle ?? this.hasSaddle,
        decorations: decorations ?? this.decorations,
      );
}
