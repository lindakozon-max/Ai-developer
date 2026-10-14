import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

class FarmGame extends FlameGame {
  FarmGame({required this.onAnimalTapped});
  final void Function() onAnimalTapped;
  PlayerComponent? player;

  @override
  Future<void> onLoad() async {
    add(FarmBackground());
    player = PlayerComponent()..position = Vector2(size.x * .5, size.y * .62);
    add(player!);
    add(AnimalComponent(onTap: onAnimalTapped)..position = Vector2(size.x * .5, size.y * .35));
  }

  void movePlayer(Vector2 delta) {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    currentPlayer.position += delta;
    currentPlayer.position.clamp(Vector2.all(24), size - Vector2.all(24));
  }

  void handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final delta = Vector2.zero();
      if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) delta.x -= 8;
      if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) delta.x += 8;
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) delta.y -= 8;
      if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) delta.y += 8;
      movePlayer(delta);
    }
  }
}

class FarmBackground extends Component with HasGameRef<FarmGame> {
  @override
  void render(Canvas canvas) {
    final s = gameRef.size;
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
