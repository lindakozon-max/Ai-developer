import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';

import 'domain/animal.dart';
import 'domain/dragon.dart';
import 'domain/horse.dart';
import 'domain/farm_item.dart';
import 'domain/weather.dart';

part 'farm_scenery.dart';
part 'farm_purchases.dart';
part 'dragon_component.dart';

class FarmGame extends FlameGame {
  FarmGame({
    required this.onAnimalTapped,
    required this.onHorseTapped,
    this.onDragonTapped,
    this.initialAnimals = const [],
    this.initialHorses = const [],
    this.initialDragons = const [],
  });

  final void Function(AnimalComponent animal) onAnimalTapped;
  final void Function(HorseComponent horse) onHorseTapped;
  final void Function(DragonComponent dragon)? onDragonTapped;
  final List<Animal> initialAnimals;
  final List<Horse> initialHorses;
  final List<Dragon> initialDragons;
  PlayerComponent? player;
  final List<AnimalComponent> animals = [];
  final List<HorseComponent> horses = [];
  final List<DragonComponent> dragons = [];
  final Set<LogicalKeyboardKey> _heldKeys = {};
  final Vector2 _touchDirection = Vector2.zero();
  String? _riddenHorseId;
  String? _riddenDragonId;
  WeatherSnapshot? weather;
  Set<FarmItem> ownedPurchases = {};

  // One pen per kind; horses use the sixth pen until mounted.
  Rect enclosure(int index) => index == 6
      ? Rect.fromLTWH(size.x * .03, size.y * .01, size.x * .46, size.y * .17)
      : Rect.fromLTWH(
          size.x * (.04 + (index % 2) * .49),
          size.y * (.20 + (index ~/ 2) * .25),
          size.x * .43,
          size.y * .22,
        );

  Vector2 confinedPosition(Vector2 point, int pen, Vector2 body) {
    final rect = enclosure(pen);
    final mx = min(body.x / 2 + 4, rect.width / 2);
    final my = min(body.y / 2 + 4, rect.height / 2);
    return Vector2(
      point.x.clamp(rect.left + mx, rect.right - mx).toDouble(),
      point.y.clamp(rect.top + my, rect.bottom - my).toDouble(),
    );
  }

  @override
  Future<void> onLoad() async {
    add(FarmBackground());
    add(EnclosureBackground()..priority = 1);
    add(FarmPurchases()..priority = 40);
    add(WeatherOverlay()..priority = 200);
    player = PlayerComponent()
      ..position = boundedPosition(Vector2(size.x * .5, size.y * .62), 24)
      ..priority = 100;
    add(player!);
    final startingAnimals = initialAnimals.isEmpty
        ? [
            const Animal(
              id: 'biscuit',
              name: 'Biscuit',
              kind: AnimalKind.sheep,
              variant: AnimalVariant.ivory,
              needs: AnimalNeeds(hunger: 55, happiness: 65),
            ),
          ]
        : initialAnimals;
    for (final animal in startingAnimals) {
      addAnimal(animal);
    }
    final startingHorses = initialHorses.isEmpty
        ? [
            const Horse(
              id: 'horse-1',
              name: 'Clover',
              variant: HorseVariant.chestnut,
            ),
          ]
        : initialHorses;
    for (final horse in startingHorses) {
      addHorse(horse);
    }
    for (final dragon in initialDragons) {
      addDragon(dragon);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final delta = _touchDirection.clone();
    if (_heldKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _heldKeys.contains(LogicalKeyboardKey.keyA)) {
      delta.x -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _heldKeys.contains(LogicalKeyboardKey.keyD)) {
      delta.x += 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _heldKeys.contains(LogicalKeyboardKey.keyW)) {
      delta.y -= 1;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _heldKeys.contains(LogicalKeyboardKey.keyS)) {
      delta.y += 1;
    }
    if (delta.length2 > 0) {
      movePlayer(
        delta.normalized() *
            (_riddenDragonId != null
                ? 340
                : _riddenHorseId == null
                ? 180
                : 290) *
            dt,
      );
    }
  }

  Vector2 boundedPosition(Vector2 point, double margin) {
    final insetX = min(margin, max(0.0, size.x / 2));
    final insetY = min(margin, max(0.0, size.y / 2));
    return Vector2(
      point.x.clamp(insetX, max(insetX, size.x - insetX)).toDouble(),
      point.y.clamp(insetY, max(insetY, size.y - insetY)).toDouble(),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    for (final animal in animals) {
      animal.position.setFrom(
        confinedPosition(
          animal.position,
          animal.animal.kind.index,
          animal.size,
        ),
      );
    }
    for (final horse in horses) {
      horse.position.setFrom(
        horse.isRidden
            ? boundedPosition(horse.position, 52)
            : confinedPosition(horse.position, 5, horse.size),
      );
    }
    for (final dragon in dragons) {
      dragon.position.setFrom(
        dragon.isRidden
            ? boundedPosition(dragon.position, 52)
            : confinedPosition(dragon.position, 6, dragon.size),
      );
    }
    if (player != null) {
      final mount = _riddenHorse ?? _riddenDragon;
      player!.position.setFrom(
        mount?.position ?? boundedPosition(player!.position, 24),
      );
    }
  }

  HorseComponent? get _riddenHorse {
    for (final horse in horses) {
      if (horse.id == _riddenHorseId) return horse;
    }
    return null;
  }

  DragonComponent? get _riddenDragon {
    for (final dragon in dragons) {
      if (dragon.id == _riddenDragonId) return dragon;
    }
    return null;
  }

  void movePlayer(Vector2 delta) {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    final mount = _riddenHorse ?? _riddenDragon;
    if (mount != null) {
      mount.position.setFrom(boundedPosition(mount.position + delta, 52));
      mount.animateMovement(delta);
      currentPlayer.position.setFrom(mount.position);
    } else {
      currentPlayer.position.setFrom(
        boundedPosition(currentPlayer.position + delta, 24),
      );
    }
    currentPlayer.animateMovement(delta);
  }

  void setMoveDirection(Vector2 direction) {
    _touchDirection.setFrom(direction);
    if (_touchDirection.length2 > 1) _touchDirection.normalize();
  }

  void clearMovement() {
    _heldKeys.clear();
    _touchDirection.setZero();
  }

  void handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _heldKeys
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyUpEvent) {
      _heldKeys.remove(event.logicalKey);
    } else {
      _heldKeys.add(event.logicalKey);
    }
  }

  void setRiddenHorse(String? id) {
    if (_riddenHorseId == id) return;
    if (id != null && _riddenDragonId != null) return;
    HorseComponent? next;
    if (id != null) {
      for (final horse in horses) {
        if (horse.id == id && horse.horse.hasSaddle) next = horse;
      }
      if (next == null) return;
    }
    final previous = _riddenHorse;
    if (previous != null) {
      previous.isRidden = false;
      previous.position.setFrom(
        confinedPosition(previous.position, 5, previous.size),
      );
      player?.position.setFrom(
        boundedPosition(previous.position + Vector2(0, 52), 24),
      );
    }
    _riddenHorseId = next?.id;
    player?.isRiding = next != null || _riddenDragonId != null;
    if (next != null) {
      next.isRidden = true;
      player?.position.setFrom(next.position);
    }
    clearMovement();
  }

  void setRiddenDragon(String? id) {
    if (_riddenDragonId == id) return;
    if (id != null && _riddenHorseId != null) return;
    DragonComponent? next;
    if (id != null) {
      for (final dragon in dragons) {
        if (dragon.id == id && dragon.hasSaddle) next = dragon;
      }
      if (next == null) return;
    }
    final previous = _riddenDragon;
    if (previous != null) {
      previous.isRidden = false;
      previous.priority = 35;
      previous.position.setFrom(
        confinedPosition(previous.position, 6, previous.size),
      );
      player?.position.setFrom(
        boundedPosition(previous.position + Vector2(0, 52), 24),
      );
    }
    _riddenDragonId = next?.id;
    player?.isRiding = next != null || _riddenHorseId != null;
    if (next != null) {
      next.isRidden = true;
      next.priority = 90;
      player?.position.setFrom(next.position);
    }
    clearMovement();
  }

  void addDragon(Dragon dragon) {
    if (dragons.any((component) => component.id == dragon.id)) return;
    final component = DragonComponent(
      dragon: dragon,
      onTap: (d) => onDragonTapped?.call(d),
    )..priority = 35;
    final roost = enclosure(6);
    component.position.setFrom(
      confinedPosition(
        Vector2(roost.center.dx, roost.center.dy),
        6,
        component.size,
      ),
    );
    dragons.add(component);
    add(component);
  }

  void syncDragon(Dragon dragon) {
    for (final component in dragons) {
      if (component.id == dragon.id) {
        component.dragon = dragon;
        if (!dragon.hasSaddle && component.isRidden) setRiddenDragon(null);
        return;
      }
    }
  }

  void removeAnimal(String id) {
    for (final component in animals.where((a) => a.id == id).toList()) {
      component.removeFromParent();
      animals.remove(component);
    }
  }

  void removeHorse(String id) {
    if (_riddenHorseId == id) setRiddenHorse(null);
    for (final component in horses.where((h) => h.id == id).toList()) {
      component.removeFromParent();
      horses.remove(component);
    }
  }

  void removeDragon(String id) {
    if (_riddenDragonId == id) setRiddenDragon(null);
    for (final component in dragons.where((d) => d.id == id).toList()) {
      component.removeFromParent();
      dragons.remove(component);
    }
  }

  Vector2 _spawnPosition(int index, {bool horse = false}) {
    if (!horse && index < 5) {
      // Space the starter herd apart so every animal has its own tap target.
      const starters = [
        Offset(.50, .35),
        Offset(.20, .30),
        Offset(.80, .50),
        Offset(.50, .77),
        Offset(.80, .77),
      ];
      final spot = starters[index];
      return boundedPosition(Vector2(size.x * spot.dx, size.y * spot.dy), 48);
    }
    // Wrap rows and columns so expanding a herd never spawns off screen.
    final column = index % 5;
    final row = (index ~/ 5) % 4;
    return boundedPosition(
      Vector2(
        size.x * (.18 + column * .16),
        size.y * ((horse ? .52 : .31) + row * .10),
      ),
      horse ? 52 : 48,
    );
  }

  void addAnimal(Animal animal) {
    if (animals.any((component) => component.id == animal.id)) return;
    final component = AnimalComponent(animal: animal, onTap: onAnimalTapped)
      ..position = animals.isEmpty
          ? boundedPosition(Vector2(size.x * .5, size.y * .35), 48)
          : _spawnPosition(animals.length)
      ..priority = 20;
    final pen = enclosure(animal.kind.index);
    component.position.setFrom(
      confinedPosition(
        Vector2(pen.center.dx, pen.center.dy),
        animal.kind.index,
        component.size,
      ),
    );
    animals.add(component);
    add(component);
  }

  void addHorse(Horse horse) {
    if (horses.any((component) => component.id == horse.id)) return;
    final component = HorseComponent(horse: horse, onTap: onHorseTapped)
      ..position = _spawnPosition(horses.length, horse: true)
      ..priority = 30;
    final pen = enclosure(5);
    component.position.setFrom(
      confinedPosition(
        Vector2(pen.center.dx, pen.center.dy),
        5,
        component.size,
      ),
    );
    horses.add(component);
    add(component);
  }

  void syncHorse(Horse horse) {
    for (final component in horses) {
      if (component.id == horse.id) {
        component.horse = horse;
        if (!horse.hasSaddle && component.isRidden) setRiddenHorse(null);
        return;
      }
    }
  }
}

class FarmBackground extends Component with HasGameReference<FarmGame> {
  @override
  void render(Canvas canvas) {
    final s = game.size;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.x, s.y),
      Paint()..color = const Color(0xffffe7b8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.x * .06, s.y * .16, s.x * .88, s.y * .72),
        const Radius.circular(28),
      ),
      Paint()..color = const Color(0xffb9df9d),
    );
    canvas.drawOval(
      Rect.fromLTWH(s.x * .22, s.y * .48, s.x * .56, s.y * .28),
      Paint()..color = const Color(0xffefd29a),
    );
    canvas.drawOval(
      Rect.fromLTWH(s.x * .1, s.y * .23, s.x * .25, s.y * .14),
      Paint()..color = const Color(0xff93d6e4),
    );
    canvas.drawRect(
      Rect.fromLTWH(s.x * .68, s.y * .24, s.x * .18, s.y * .2),
      Paint()..color = const Color(0xffe8927e),
    );
    canvas.drawPath(
      Path()
        ..moveTo(s.x * .65, s.y * .24)
        ..lineTo(s.x * .77, s.y * .12)
        ..lineTo(s.x * .89, s.y * .24)
        ..close(),
      Paint()..color = const Color(0xffc96f78),
    );
  }
}

class PlayerComponent extends PositionComponent {
  PlayerComponent() : super(size: Vector2.all(34), anchor: Anchor.center);
  bool isRiding = false;
  double _phase = 0;
  double _movingFor = 0;

  void animateMovement(Vector2 delta) {
    if (delta.length2 > 0) _movingFor = .12;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 12;
    _movingFor = max(0, _movingFor - dt);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (isRiding) {
      canvas.translate(0, -18);
      _line(
        canvas,
        const Offset(10, 25),
        const Offset(5, 40),
        const Color(0xff4e4572),
        5,
      );
      _line(
        canvas,
        const Offset(24, 25),
        const Offset(29, 40),
        const Color(0xff4e4572),
        5,
      );
    } else if (_movingFor > 0) {
      canvas.translate(0, sin(_phase) * 1.5);
    }
    canvas.drawCircle(
      const Offset(17, 17),
      14,
      Paint()..color = const Color(0xff9b77d7),
    );
    canvas.drawCircle(
      const Offset(12, 13),
      3,
      Paint()..color = const Color(0xffffffff),
    );
    canvas.drawCircle(
      const Offset(22, 13),
      3,
      Paint()..color = const Color(0xffffffff),
    );
    canvas.drawCircle(
      const Offset(13, 13),
      1.4,
      Paint()..color = const Color(0xff46364e),
    );
    canvas.drawCircle(
      const Offset(23, 13),
      1.4,
      Paint()..color = const Color(0xff46364e),
    );
    canvas.restore();
  }
}

// All farm animals alternate gentle wandering and resting, with independent
// animation phases so a whole herd does not move in lockstep.
abstract class WanderingComponent extends PositionComponent
    with HasGameReference<FarmGame> {
  WanderingComponent({required Vector2 size})
    : super(size: size, anchor: Anchor.center);
  final Random _random = Random();
  Vector2 _direction = Vector2.zero();
  double _changeDirectionIn = 2;
  double phase = 0;
  double _movingFor = 0;
  bool facingLeft = false;
  bool get isRidden => false;
  int get penIndex;
  double get walkSpeed => 15;
  bool get isWalking => _movingFor > 0;
  double get stride => isWalking ? sin(phase * 8) * 4 : 0;
  double get bob => sin(phase * (isWalking ? 8 : 2)) * (isWalking ? 1.1 : .65);

  void animateMovement(Vector2 delta) {
    if (delta.length2 == 0) return;
    _movingFor = .14;
    if (delta.x.abs() > .01) facingLeft = delta.x < 0;
  }

  @override
  Future<void> onLoad() async {
    phase = _random.nextDouble() * pi * 2;
    _changeDirectionIn += _random.nextDouble() * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    phase += dt;
    _movingFor = max(0, _movingFor - dt);
    if (isRidden) return;
    _changeDirectionIn -= dt;
    if (_changeDirectionIn <= 0) {
      _changeDirectionIn = 1.5 + _random.nextDouble() * 3;
      _direction = _random.nextDouble() < .25
          ? Vector2.zero()
          : Vector2(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      if (_direction.length2 > 0) _direction.normalize();
    }
    final delta = _direction * walkSpeed * dt;
    final next = game.confinedPosition(position + delta, penIndex, size);
    if ((next.x - position.x - delta.x).abs() > .01) _direction.x *= -1;
    if ((next.y - position.y - delta.y).abs() > .01) _direction.y *= -1;
    final movement = next - position;
    position.setFrom(next);
    animateMovement(movement);
  }

  void beginAnimal(Canvas canvas) {
    canvas.save();
    canvas.drawOval(
      Rect.fromLTWH(12, size.y - 10, size.x - 24, 9),
      Paint()..color = const Color(0x18574039),
    );
    if (facingLeft) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    canvas.translate(0, bob);
  }

  void drawEye(Canvas canvas, Offset eye) {
    final blinking = phase % 4.5 > 4.32;
    if (blinking) {
      _line(
        canvas,
        eye - const Offset(2, 0),
        eye + const Offset(2, 0),
        const Color(0xff352d38),
        1.8,
      );
    } else {
      canvas.drawCircle(eye, 2.4, Paint()..color = const Color(0xff352d38));
      canvas.drawCircle(
        eye + const Offset(.7, -.7),
        .7,
        Paint()..color = const Color(0xffffffff),
      );
    }
  }
}

class AnimalComponent extends WanderingComponent with TapCallbacks {
  AnimalComponent({required this.animal, required this.onTap})
    : super(size: Vector2(90, 76));
  final Animal animal;
  final void Function(AnimalComponent animal) onTap;
  String get id => animal.id;
  @override
  int get penIndex => animal.kind.index;

  @override
  double get walkSpeed => animal.kind == AnimalKind.chicken ? 21 : 13;

  Color get coat => switch (animal.variant) {
    AnimalVariant.ivory => const Color(0xfffff2dc),
    AnimalVariant.brown => const Color(0xffaf7954),
    AnimalVariant.black => const Color(0xff45424c),
    AnimalVariant.spotted => const Color(0xfff6ece0),
    AnimalVariant.grey => const Color(0xffa5acb4),
    AnimalVariant.cream => const Color(0xffffdfa5),
    AnimalVariant.golden => const Color(0xffdcad43),
    AnimalVariant.chestnut => const Color(0xff984d38),
    AnimalVariant.silver => const Color(0xffd5dce2),
    AnimalVariant.piebald => const Color(0xfffafafa),
  };

  @override
  void render(Canvas canvas) {
    beginAnimal(canvas);
    if (animal.kind == AnimalKind.chicken) {
      _drawChicken(canvas);
    } else {
      _drawHoofedAnimal(canvas);
    }
    canvas.restore();
  }

  void _drawHoofedAnimal(Canvas canvas) {
    final isSheep = animal.kind == AnimalKind.sheep;
    final isGoat = animal.kind == AnimalKind.goat;
    final isCow = animal.kind == AnimalKind.cow;
    final isDonkey = animal.kind == AnimalKind.donkey;
    final legColor = isSheep ? const Color(0xff7e6b5e) : coat;
    for (final x in [25.0, 55.0]) {
      for (final side in [-1.0, 1.0]) {
        final foot = Offset(x + side * 5 + stride * side, 67);
        _line(canvas, Offset(x + side * 5, 47), foot, legColor, 5);
        _line(
          canvas,
          foot - const Offset(1.5, 0),
          foot + const Offset(2, 0),
          const Color(0xff514653),
          5,
        );
      }
    }
    final tailY = 33 + sin(phase * 3) * 5;
    _line(
      canvas,
      const Offset(17, 36),
      Offset(7, tailY),
      coat,
      isSheep ? 7 : 3,
    );
    if (isCow || isDonkey) {
      _line(
        canvas,
        Offset(7, tailY),
        Offset(5, tailY + 8),
        const Color(0xff5b4b48),
        4,
      );
    }
    if (isCow) {
      canvas.drawOval(
        const Rect.fromLTWH(38, 44, 18, 11),
        Paint()..color = const Color(0xffe9a2aa),
      );
      _line(
        canvas,
        const Offset(43, 52),
        const Offset(43, 57),
        const Color(0xffe9a2aa),
        3,
      );
      _line(
        canvas,
        const Offset(51, 52),
        const Offset(51, 57),
        const Color(0xffe9a2aa),
        3,
      );
    }
    canvas.drawOval(const Rect.fromLTWH(15, 25, 54, 31), Paint()..color = coat);
    if (isSheep) {
      for (final offset in [
        const Offset(23, 28),
        const Offset(36, 23),
        const Offset(50, 24),
        const Offset(61, 31),
        const Offset(23, 43),
        const Offset(35, 49),
        const Offset(49, 49),
        const Offset(61, 43),
      ]) {
        canvas.drawCircle(offset, 10, Paint()..color = coat);
        canvas.drawArc(
          Rect.fromCircle(center: offset, radius: 7),
          pi,
          1.8,
          false,
          Paint()
            ..color = const Color(0x20756564)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }
    }
    if (animal.variant == AnimalVariant.spotted ||
        animal.variant == AnimalVariant.piebald ||
        isCow) {
      final spot = Paint()
        ..color = animal.variant == AnimalVariant.black
            ? const Color(0xffb6ac9c)
            : const Color(0xff64524d);
      canvas.drawOval(const Rect.fromLTWH(24, 29, 13, 15), spot);
      canvas.drawOval(const Rect.fromLTWH(47, 39, 14, 10), spot);
      if (animal.variant == AnimalVariant.spotted) {
        canvas.drawCircle(const Offset(44, 27), 5, spot);
      }
    }
    if (isDonkey) {
      _line(canvas, const Offset(60, 31), const Offset(66, 15), coat, 15);
      _line(canvas, const Offset(65, 12), const Offset(61, 1), coat, 7);
      _line(canvas, const Offset(74, 12), const Offset(78, 1), coat, 7);
      _line(
        canvas,
        const Offset(65, 10),
        const Offset(62, 3),
        const Color(0xffdba7a2),
        3,
      );
      _line(
        canvas,
        const Offset(73, 10),
        const Offset(77, 3),
        const Color(0xffdba7a2),
        3,
      );
      _line(
        canvas,
        const Offset(58, 29),
        const Offset(59, 15),
        const Color(0xff5c504d),
        5,
      );
    }
    canvas.drawOval(
      Rect.fromLTWH(58, isDonkey ? 12 : 20, 24, 27),
      Paint()..color = isSheep ? const Color(0xffc8b6a0) : coat,
    );
    if (!isDonkey) {
      canvas.drawOval(
        const Rect.fromLTWH(51, 20, 16, 8),
        Paint()..color = coat,
      );
      canvas.drawOval(
        const Rect.fromLTWH(75, 20, 12, 7),
        Paint()..color = coat,
      );
    }
    if (isGoat || isCow) {
      final horn = Paint()
        ..color = const Color(0xffddc99e)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(62, 24)
          ..quadraticBezierTo(55, 10, 61, 8),
        horn,
      );
      canvas.drawPath(
        Path()
          ..moveTo(75, 23)
          ..quadraticBezierTo(81, 11, 76, 7),
        horn,
      );
    }
    if (isGoat) {
      canvas.drawPath(
        Path()
          ..moveTo(70, 43)
          ..lineTo(76, 54 + sin(phase * 3))
          ..lineTo(80, 42)
          ..close(),
        Paint()..color = coat,
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(69, 35, 17, 12),
      Paint()
        ..color = isCow ? const Color(0xffe7a8ae) : const Color(0xffd0b99d),
    );
    canvas.drawCircle(
      const Offset(81, 39),
      1.5,
      Paint()..color = const Color(0xff75605a),
    );
    drawEye(canvas, Offset(73, isDonkey ? 24 : 29));
  }

  void _drawChicken(Canvas canvas) {
    for (final x in [38.0, 54.0]) {
      final foot = Offset(x + stride, 67);
      _line(canvas, Offset(x, 51), foot, const Color(0xffd79c32), 3);
      _line(
        canvas,
        foot - const Offset(4, 0),
        foot + const Offset(4, 0),
        const Color(0xffd79c32),
        2,
      );
    }
    final feather = Paint()..color = coat;
    canvas.drawOval(const Rect.fromLTWH(21, 29, 43, 29), feather);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromLTWH(15 + i * 4, 18 + i * 3 + sin(phase * 4), 11, 25),
        feather,
      );
    }
    canvas.drawCircle(const Offset(63, 27), 13, feather);
    final wingColor = Color.lerp(coat, const Color(0xff6e594a), .22)!;
    canvas.save();
    canvas.translate(42, 42);
    canvas.rotate(sin(phase * (isWalking ? 10 : 2)) * .17);
    canvas.drawOval(
      const Rect.fromLTWH(-13, -7, 24, 17),
      Paint()..color = wingColor,
    );
    canvas.restore();
    if (animal.variant == AnimalVariant.spotted) {
      canvas.drawCircle(
        const Offset(31, 34),
        4,
        Paint()..color = const Color(0xff594742),
      );
      canvas.drawCircle(
        const Offset(49, 49),
        3,
        Paint()..color = const Color(0xff594742),
      );
      canvas.drawCircle(
        const Offset(61, 23),
        3,
        Paint()..color = const Color(0xff594742),
      );
    }
    final red = Paint()..color = const Color(0xffdb6965);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(57 + i * 5, 15.0), 4, red);
    }
    canvas.drawOval(const Rect.fromLTWH(65, 35, 6, 10), red);
    canvas.drawPath(
      Path()
        ..moveTo(74, 26)
        ..lineTo(85, 31)
        ..lineTo(73, 35)
        ..close(),
      Paint()..color = const Color(0xffe6af36),
    );
    drawEye(canvas, const Offset(68, 25));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(this);
}

class HorseComponent extends WanderingComponent with TapCallbacks {
  HorseComponent({required this.horse, required this.onTap})
    : super(size: Vector2(92, 72));
  Horse horse;
  final void Function(HorseComponent horse) onTap;
  String get id => horse.id;
  @override
  int get penIndex => 5;
  HorseVariant get variant => horse.variant;
  bool get hasSaddle => horse.hasSaddle;
  Set<String> get decorations => horse.decorations;
  @override
  bool isRidden = false;
  @override
  double get walkSpeed => 22;

  @override
  void render(Canvas canvas) {
    beginAnimal(canvas);
    final baseColor = switch (variant) {
      HorseVariant.chestnut => const Color(0xff9b573f),
      HorseVariant.palomino => const Color(0xffe7b957),
      HorseVariant.dapple => const Color(0xff8f8f9f),
      HorseVariant.black => const Color(0xff393642),
      HorseVariant.grey => const Color(0xffc8ccd1),
    };
    final color = switch (horse.style) {
      HorseStyle.golden => const Color(0xffe5b83c),
      HorseStyle.midnight => const Color(0xff292851),
      HorseStyle.celestial => const Color(0xff9188d5),
      _ =>
        horse.breed == HorseBreed.friesian
            ? const Color(0xff24232d)
            : baseColor,
    };
    final mane = horse.breed == HorseBreed.friesian
        ? const Color(0xff14131c)
        : variant == HorseVariant.palomino || variant == HorseVariant.grey
        ? const Color(0xfff5e5c5)
        : const Color(0xff513b3a);
    final body = Paint()..color = color;
    final tail = Path()
      ..moveTo(17, 29)
      ..quadraticBezierTo(1, 28, 8 + sin(phase * 3) * 4, 53);
    canvas.drawPath(
      tail,
      Paint()
        ..color = mane
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    for (final x in [25.0, 57.0]) {
      for (final side in [-1.0, 1.0]) {
        final foot = Offset(x + side * 5 + stride * side, 66);
        _line(canvas, Offset(x + side * 5, 44), foot, color, 6);
        _line(
          canvas,
          foot - const Offset(2, 0),
          foot + const Offset(2, 0),
          const Color(0xff493d44),
          5,
        );
      }
    }
    canvas.drawOval(const Rect.fromLTWH(14, 22, 58, 30), body);
    if (horse.style == HorseStyle.rainbow) {
      canvas.save();
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(14, 22, 58, 30)));
      const stripes = [
        Color(0xffed7b92),
        Color(0xfff7bd61),
        Color(0xffeddc6d),
        Color(0xff7ccda0),
        Color(0xff7bb5e2),
        Color(0xffb28bda),
      ];
      for (var i = 0; i < stripes.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(14 + i * 10, 22, 10, 30),
          Paint()..color = stripes[i],
        );
      }
      canvas.restore();
    }
    if (horse.breed == HorseBreed.friesian) {
      for (final x in [21.0, 31.0, 53.0, 63.0]) {
        canvas.drawOval(Rect.fromLTWH(x - 4, 58, 10, 9), Paint()..color = mane);
      }
      for (var i = 0; i < 5; i++) {
        _line(
          canvas,
          Offset(58 + i * 2, 21 - i * 2),
          Offset(51 + i * 2, 39.0 - i),
          mane,
          4,
        );
      }
    }
    if (horse.style == HorseStyle.spotted ||
        horse.style == HorseStyle.celestial) {
      for (var i = 0; i < 6; i++) {
        final point = Offset(23 + (i % 3) * 16, 30 + (i ~/ 3) * 12);
        canvas.drawCircle(
          point,
          horse.style == HorseStyle.spotted ? 4 : 2,
          Paint()
            ..color = horse.style == HorseStyle.spotted
                ? const Color(0xfffbf1dd)
                : const Color(0xffffe9a3),
        );
      }
    }
    _line(canvas, const Offset(62, 36), const Offset(71, 18), color, 20);
    _line(canvas, const Offset(60, 30), const Offset(67, 13), mane, 7);
    canvas.drawCircle(const Offset(76, 22), 14, body);
    canvas.drawOval(
      const Rect.fromLTWH(77, 26, 15, 12),
      Paint()..color = Color.lerp(color, const Color(0xffffe8d6), .25)!,
    );
    canvas.drawPath(
      Path()
        ..moveTo(72, 12)
        ..lineTo(70, 1)
        ..lineTo(79, 10)
        ..close(),
      body,
    );
    canvas.drawPath(
      Path()
        ..moveTo(81, 12)
        ..lineTo(86, 2)
        ..lineTo(86, 18)
        ..close(),
      body,
    );
    canvas.drawOval(const Rect.fromLTWH(66, 7, 17, 8), Paint()..color = mane);
    if (variant == HorseVariant.dapple) {
      for (final spot in [
        const Offset(25, 31),
        const Offset(41, 40),
        const Offset(54, 30),
        const Offset(31, 43),
      ]) {
        canvas.drawCircle(spot, 4, Paint()..color = const Color(0xffc9c9d4));
      }
    } else if (variant == HorseVariant.chestnut ||
        variant == HorseVariant.grey) {
      _line(
        canvas,
        const Offset(80, 17),
        const Offset(82, 28),
        const Color(0xfff6e9d5),
        3,
      );
    }
    drawEye(canvas, const Offset(80, 19));
    canvas.drawCircle(
      const Offset(88, 31),
      1.4,
      Paint()..color = const Color(0xff5a4546),
    );
    if (horse.saddle != null) _drawSaddle(canvas, horse.saddle!);
    if (decorations.contains('flower')) {
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(66 + cos(i * pi * .4) * 4, 12 + sin(i * pi * .4) * 4),
          3,
          Paint()..color = const Color(0xffed91ab),
        );
      }
      canvas.drawCircle(
        const Offset(66, 12),
        2.2,
        Paint()..color = const Color(0xffffdf79),
      );
    }
    if (isRidden) {
      canvas.drawPath(
        Path()
          ..moveTo(83, 31)
          ..quadraticBezierTo(61, 40, 46, 19),
        Paint()
          ..color = const Color(0xff654833)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();
  }

  void _drawSaddle(Canvas canvas, SaddleType type) {
    final (blanket, leather) = switch (type) {
      SaddleType.classic => (const Color(0xffc98167), const Color(0xff5f3b2d)),
      SaddleType.western => (const Color(0xffddbc73), const Color(0xff8a5533)),
      SaddleType.racing => (const Color(0xffe67272), const Color(0xff333c58)),
      SaddleType.royal => (const Color(0xff7950aa), const Color(0xffd3a54e)),
      SaddleType.trail => (const Color(0xff75a58a), const Color(0xff665340)),
      SaddleType.dressage => (const Color(0xfff0eee5), const Color(0xff282a3d)),
      SaddleType.endurance => (
        const Color(0xff58a2a8),
        const Color(0xff644e3e),
      ),
      SaddleType.jousting => (const Color(0xff9f4355), const Color(0xffbdab74)),
      SaddleType.sky => (const Color(0xff89cdeb), const Color(0xff4f6394)),
      SaddleType.ember => (const Color(0xffe38142), const Color(0xff692e35)),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 20, 34, 24),
        const Radius.circular(5),
      ),
      Paint()..color = blanket,
    );
    final seat = type == SaddleType.racing
        ? const Rect.fromLTWH(34, 18, 20, 12)
        : const Rect.fromLTWH(31, 16, 29, 17);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seat, const Radius.circular(5)),
      Paint()..color = leather,
    );
    _line(canvas, const Offset(42, 30), const Offset(42, 47), leather, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 42, 9, 7),
        const Radius.circular(2),
      ),
      Paint()
        ..color = const Color(0xffe6cb91)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    switch (type) {
      case SaddleType.dressage:
      case SaddleType.endurance:
      case SaddleType.jousting:
      case SaddleType.sky:
      case SaddleType.ember:
        canvas.drawCircle(const Offset(50, 35), 4, Paint()..color = leather);
        for (var i = 0; i <= type.index - 5; i++) {
          _line(
            canvas,
            Offset(30.0 + i * 5, 39),
            Offset(32.0 + i * 5, 43),
            leather,
            2,
          );
        }
      case SaddleType.classic:
        _line(
          canvas,
          const Offset(33, 32),
          const Offset(57, 32),
          const Color(0xffe4c18a),
          2,
        );
      case SaddleType.western:
        _line(canvas, const Offset(55, 20), const Offset(55, 10), leather, 4);
        _line(canvas, const Offset(51, 10), const Offset(59, 10), leather, 4);
        for (var x = 30.0; x < 62; x += 5) {
          _line(canvas, Offset(x, 40), Offset(x, 46), leather, 1.5);
        }
      case SaddleType.racing:
        _line(
          canvas,
          const Offset(50, 34),
          const Offset(56, 34),
          const Color(0xffffffff),
          2,
        );
        _line(
          canvas,
          const Offset(56, 34),
          const Offset(51, 41),
          const Color(0xffffffff),
          2,
        );
      case SaddleType.royal:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(29, 21, 32, 22),
            const Radius.circular(4),
          ),
          Paint()
            ..color = leather
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawPath(
          Path()
            ..moveTo(50, 36)
            ..lineTo(48, 30)
            ..lineTo(53, 33)
            ..lineTo(56, 28)
            ..lineTo(59, 36)
            ..close(),
          Paint()..color = leather,
        );
      case SaddleType.trail:
        for (final x in [24.0, 55.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 32, 13, 15),
              const Radius.circular(3),
            ),
            Paint()..color = leather,
          );
          _line(canvas, Offset(x + 2, 36), Offset(x + 11, 36), blanket, 2);
        }
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(this);
}

void _line(Canvas canvas, Offset from, Offset to, Color color, double width) {
  canvas.drawLine(
    from,
    to,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
}
