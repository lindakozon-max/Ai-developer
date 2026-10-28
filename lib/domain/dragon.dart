import 'horse.dart';

enum DragonElement { fire, ice, forest, storm }

/// Inherited elements and parent IDs are independent from riding equipment.
class Dragon {
  const Dragon({
    required this.id,
    required this.name,
    this.elements = const {DragonElement.fire},
    this.parentIds = const [],
    this.saddle,
    this.ownedSaddles = const {},
  });

  final String id;
  final String name;
  final Set<DragonElement> elements;
  final List<String> parentIds;
  final SaddleType? saddle;
  final Set<SaddleType> ownedSaddles;
  bool get hasSaddle => saddle != null;
  bool get isHybrid => elements.length > 1;
  int get marketPrice => isHybrid ? 400 : 250;

  Dragon copyWith({SaddleType? saddle, Set<SaddleType>? ownedSaddles}) =>
      Dragon(
        id: id,
        name: name,
        elements: elements,
        parentIds: parentIds,
        saddle: saddle ?? this.saddle,
        ownedSaddles: ownedSaddles ?? this.ownedSaddles,
      );
}
