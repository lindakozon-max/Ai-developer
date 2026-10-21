import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'domain/horse.dart';

class FarmGame extends FlameGame {
  FarmGame({required this.onAnimalTapped, required this.onHorseTapped});
  final void Function() onAnimalTapped;
  final void Function(HorseComponent horse) onHorseTapped;
  PlayerComponent? player;
  final List<HorseComponent> horses = [];
  final Set<LogicalKeyboardKey> _heldKeys = {};

  @override
  Future<void> onLoad() async {
    add(FarmBackground());
    player = PlayerComponent()..position = Vector2(size.x * .5, size.y * .62);
    add(player!);
    add(AnimalComponent(onTap: onAnimalTapped)..position = Vector2(size.x * .5, size.y * .35));
    addHorse(HorseVariant.chestnut);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final delta = Vector2.zero();
    if (_heldKeys.contains(LogicalKeyboardKey.arrowLeft) || _heldKeys.contains(LogicalKeyboardKey.keyA)) delta.x -= 1;
    if (_heldKeys.contains(LogicalKeyboardKey.arrowRight) || _heldKeys.contains(LogicalKeyboardKey.keyD)) delta.x += 1;
    if (_heldKeys.contains(LogicalKeyboardKey.arrowUp) || _heldKeys.contains(LogicalKeyboardKey.keyW)) delta.y -= 1;
    if (_heldKeys.contains(LogicalKeyboardKey.arrowDown) || _heldKeys.contains(LogicalKeyboardKey.keyS)) delta.y += 1;
    if (delta.length2 > 0) movePlayer(delta.normalized() * 180 * dt);
  }

  void movePlayer(Vector2 delta) {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    currentPlayer.position += delta;
    currentPlayer.position.clamp(Vector2.all(24), size - Vector2.all(24));
  }

  void handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyUpEvent) {
      _heldKeys.remove(event.logicalKey);
    } else {
      _heldKeys.add(event.logicalKey);
      _heldKeys.addAll(keysPressed);
    }
  }

  void addHorse(HorseVariant variant) {
    final horse = HorseComponent(
      id: 'horse-${horses.length + 1}',
      variant: variant,
      onTap: onHorseTapped,
    )..position = Vector2(size.x * (.25 + horses.length * .18), size.y * .5);
    horses.add(horse);
    add(horse);
  }
}

class FarmBackground extends Component with HasGameReference<FarmGame> {
  @override
  void render(Canvas canvas) {
    final s = game.size;
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y), Paint()..color = const Color(0xffffe7b8));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.x * .06, s.y * .16, s.x * .88, s.y * .72), const Radius.circular(28)), Paint()..color = const Color(0xffb9df9d));
    canvas.drawOval(Rect.fromLTWH(s.x * .22, s.y * .48, s.x * .56, s.y * .28), Paint()..color = const Color(0xffefd29a));
    canvas.drawOval(Rect.fromLTWH(s.x * .1, s.y * .23, s.x * .25, s.y * .14), Paint()..color = const Color(0xff93d6e4));
    canvas.drawRect(Rect.fromLTWH(s.x * .68, s.y * .24, s.x * .18, s.y * .2), Paint()..color = const Color(0xffe8927e));
    canvas.drawPath(Path()..moveTo(s.x * .65, s.y * .24)..lineTo(s.x * .77, s.y * .12)..lineTo(s.x * .89, s.y * .24)..close(), Paint()..color = const Color(0xffc96f78));
  }
}

class PlayerComponent extends PositionComponent {
  PlayerComponent() : super(size: Vector2.all(34), anchor: Anchor.center);
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, Paint()..color = const Color(0xff9b77d7));
    canvas.drawCircle(const Offset(12, 13), 3, Paint()..color = const Color(0xffffffff));
    canvas.drawCircle(const Offset(22, 13), 3, Paint()..color = const Color(0xffffffff));
  }
}

class AnimalComponent extends PositionComponent with TapCallbacks {
  AnimalComponent({required this.onTap}) : super(size: Vector2.all(68), anchor: Anchor.center);
  final void Function() onTap;
  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2 + 8);
    final fur = Paint()..color = const Color(0xfffff5e6);
    canvas.drawOval(Rect.fromCenter(center: center, width: 50, height: 34), fur);
    canvas.drawCircle(Offset(center.dx + 22, center.dy - 12), 17, fur);
    canvas.drawCircle(Offset(center.dx + 27, center.dy - 14), 3, Paint()..color = const Color(0xff5b4968));
    canvas.drawCircle(Offset(center.dx + 34, center.dy - 8), 3, Paint()..color = const Color(0xffe994a0));
  }
  @override
  void onTapUp(TapUpEvent event) => onTap();
}

class HorseComponent extends PositionComponent with TapCallbacks, HasGameReference<FarmGame> {
  HorseComponent({required this.id, required this.variant, required this.onTap})
      : super(size: Vector2(92, 72), anchor: Anchor.center);

  final String id;
  final HorseVariant variant;
  final void Function(HorseComponent horse) onTap;
  final Random _random = Random();
  Vector2 _direction = Vector2.zero();
  double _changeDirectionIn = 0;
  double _legPhase = 0;
  bool hasSaddle = false;
  final Set<String> decorations = {};

  @override
  void update(double dt) {
    super.update(dt);
    _changeDirectionIn -= dt;
    _legPhase += dt * 8;
    if (_changeDirectionIn <= 0) {
      _changeDirectionIn = 1.2 + _random.nextDouble() * 2.5;
      _direction = Vector2(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      if (_direction.length2 > 0) _direction.normalize();
    }
    position += _direction * 22 * dt;
    position.clamp(Vector2(55, 55), game.size - Vector2(55, 55));
  }

  @override
  void render(Canvas canvas) {
    final color = switch (variant) {
      HorseVariant.chestnut => const Color(0xff9b573f),
      HorseVariant.palomino => const Color(0xffe7b957),
      HorseVariant.dapple => const Color(0xff8f8f9f),
    };
    final body = Paint()..color = color;
    canvas.drawOval(Rect.fromLTWH(14, 22, 58, 30), body);
    canvas.drawCircle(const Offset(76, 22), 17, body);
    canvas.drawPath(Path()..moveTo(84, 8)..lineTo(91, 2)..lineTo(88, 18)..close(), body);
    canvas.drawCircle(const Offset(81, 18), 2.5, Paint()..color = const Color(0xff3d3040));
    final legPaint = Paint()..color = color..strokeWidth = 6..strokeCap = StrokeCap.round;
    final step = sin(_legPhase) * 4;
    for (final x in [25.0, 57.0]) {
      canvas.drawLine(Offset(x, 48), Offset(x - step, 67), legPaint);
      canvas.drawLine(Offset(x + 10, 48), Offset(x + 10 + step, 67), legPaint);
    }
    if (hasSaddle) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 18, 28, 20), const Radius.circular(8)), Paint()..color = const Color(0xff5f3b2d));
      canvas.drawLine(const Offset(34, 34), const Offset(58, 34), Paint()..color = const Color(0xffe4c18a)..strokeWidth = 3);
    }
    if (decorations.contains('flower')) {
      canvas.drawCircle(const Offset(52, 16), 5, Paint()..color = const Color(0xffe994a0));
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(this);
}
