part of 'farm_game.dart';

/// Dragons share the farm's movement and tap handling, with animated wings and
/// inherited elemental colors kept separate from their temporary saddle.
class DragonComponent extends WanderingComponent with TapCallbacks {
  DragonComponent({required this.dragon, required this.onTap})
    : super(size: Vector2(100, 84));

  Dragon dragon;
  final void Function(DragonComponent dragon) onTap;
  String get id => dragon.id;
  bool get hasSaddle => dragon.hasSaddle;

  @override
  bool isRidden = false;
  @override
  int get penIndex => 6;
  @override
  double get walkSpeed => 26;

  Color _elementColor(DragonElement element) => switch (element) {
    DragonElement.fire => const Color(0xffe7805c),
    DragonElement.ice => const Color(0xff83cddd),
    DragonElement.forest => const Color(0xff79b77c),
    DragonElement.storm => const Color(0xff9786cb),
  };

  @override
  void render(Canvas canvas) {
    final elements = dragon.elements.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final first = elements.isEmpty ? DragonElement.fire : elements.first;
    final second = elements.length > 1 ? elements[1] : first;
    final bodyColor = _elementColor(first);
    final accentColor = _elementColor(second);
    final bellyColor = Color.lerp(accentColor, const Color(0xfffff2cf), .48)!;
    final wingColor = Color.lerp(accentColor, const Color(0xffffecd6), .28)!;
    final flight = sin(phase * (isRidden ? 8 : 3));

    beginAnimal(canvas);
    if (isRidden) canvas.translate(0, -5 + flight * 1.4);

    // Tail follows a separate slower wave from the wings.
    final tailEnd = Offset(4, 48 + sin(phase * 3) * 5);
    canvas.drawPath(
      Path()
        ..moveTo(26, 50)
        ..quadraticBezierTo(7, 63, tailEnd.dx, tailEnd.dy),
      Paint()
        ..color = bodyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(tailEnd.dx - 3, tailEnd.dy + 3)
        ..lineTo(tailEnd.dx + 6, tailEnd.dy - 7)
        ..lineTo(tailEnd.dx + 8, tailEnd.dy + 5)
        ..close(),
      Paint()..color = accentColor,
    );

    // The far wing opens behind the body while the near wing folds at rest.
    _drawWing(canvas, wingColor, flight, far: true);
    for (final x in [32.0, 61.0]) {
      for (final side in [-1.0, 1.0]) {
        final foot = Offset(
          x + side * 5 + (isRidden ? side * 3 : stride * side),
          isRidden ? 69 : 75,
        );
        _line(canvas, Offset(x + side * 4, 53), foot, bodyColor, 7);
        canvas.drawOval(
          Rect.fromCenter(center: foot, width: 12, height: 5),
          Paint()..color = bellyColor,
        );
      }
    }

    canvas.drawOval(
      const Rect.fromLTWH(22, 34, 54, 32),
      Paint()..color = bodyColor,
    );
    canvas.drawOval(
      const Rect.fromLTWH(39, 45, 34, 20),
      Paint()..color = bellyColor,
    );
    for (var i = 0; i < 4; i++) {
      final x = 29.0 + i * 11;
      canvas.drawPath(
        Path()
          ..moveTo(x, 38)
          ..lineTo(x + 4, 29)
          ..lineTo(x + 9, 38)
          ..close(),
        Paint()..color = accentColor,
      );
    }
    _drawWing(canvas, wingColor, flight, far: false);

    // The neck and rounded muzzle remain easy to recognize at mobile sizes.
    _line(canvas, const Offset(66, 48), const Offset(77, 31), bodyColor, 19);
    canvas.drawOval(
      const Rect.fromLTWH(65, 22, 30, 30),
      Paint()..color = bodyColor,
    );
    canvas.drawOval(
      const Rect.fromLTWH(78, 39, 20, 13),
      Paint()..color = bellyColor,
    );
    _drawElementDetails(canvas, first, accentColor);
    if (second != first) {
      // A two-tone cheek and paired wing gems visibly identify hybrid dragons.
      canvas.drawCircle(const Offset(72, 42), 5, Paint()..color = accentColor);
      canvas.drawCircle(const Offset(45, 45), 3, Paint()..color = bodyColor);
      canvas.drawCircle(const Offset(52, 48), 3, Paint()..color = accentColor);
    }
    drawEye(canvas, const Offset(85, 33));
    canvas.drawCircle(
      const Offset(94, 43),
      1.5,
      Paint()..color = const Color(0xff4e4454),
    );
    _line(
      canvas,
      const Offset(87, 48),
      const Offset(94, 49),
      const Color(0xff665264),
      1.3,
    );
    if (dragon.saddle != null) _drawSaddle(canvas, dragon.saddle!);
    if (isRidden) {
      canvas.drawPath(
        Path()
          ..moveTo(91, 47)
          ..quadraticBezierTo(75, 62, 52, 32),
        Paint()
          ..color = const Color(0xff68513c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7,
      );
    }
    canvas.restore();
  }

  void _drawWing(
    Canvas canvas,
    Color color,
    double flight, {
    required bool far,
  }) {
    final x = far ? 51.0 : 42.0;
    final spread = isRidden ? 20.0 : 12.0;
    final tip = Offset(x - 19, 24 - spread - flight * 7);
    final root = Offset(x + 10, 44);
    final wing = Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(x - 8, 36, tip.dx, tip.dy)
      ..lineTo(tip.dx + 19, tip.dy + 9)
      ..lineTo(tip.dx + 12, tip.dy + 20)
      ..lineTo(tip.dx + 29, tip.dy + 17)
      ..quadraticBezierTo(x + 10, 30, root.dx, root.dy)
      ..close();
    canvas.drawPath(
      wing,
      Paint()
        ..color = far
            ? Color.lerp(color, const Color(0xff4c405d), .18)!
            : color,
    );
    canvas.drawPath(
      wing,
      Paint()
        ..color = Color.lerp(color, const Color(0xff4c405d), .32)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _line(
      canvas,
      root,
      Offset(tip.dx + 19, tip.dy + 9),
      Color.lerp(color, const Color(0xff4c405d), .25)!,
      1.2,
    );
  }

  void _drawElementDetails(Canvas canvas, DragonElement element, Color accent) {
    switch (element) {
      case DragonElement.fire:
        for (final x in [70.0, 79.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, 27)
              ..lineTo(x - 4, 15)
              ..lineTo(x + 6, 23)
              ..close(),
            Paint()..color = const Color(0xffffd17c),
          );
        }
      case DragonElement.ice:
        for (final x in [69.0, 79.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, 27)
              ..lineTo(x - 1, 12)
              ..lineTo(x + 6, 18)
              ..lineTo(x + 4, 28)
              ..close(),
            Paint()..color = const Color(0xffd6f8ff),
          );
        }
      case DragonElement.forest:
        canvas.save();
        canvas.translate(70, 24);
        canvas.rotate(-.65);
        canvas.drawOval(
          const Rect.fromLTWH(-11, -6, 15, 8),
          Paint()..color = const Color(0xffb7df8e),
        );
        canvas.restore();
        _line(canvas, const Offset(78, 23), const Offset(80, 14), accent, 3);
      case DragonElement.storm:
        canvas.drawPath(
          Path()
            ..moveTo(72, 13)
            ..lineTo(68, 24)
            ..lineTo(75, 23)
            ..lineTo(72, 31)
            ..lineTo(84, 18)
            ..lineTo(77, 19)
            ..lineTo(80, 13)
            ..close(),
          Paint()..color = const Color(0xffffe891),
        );
    }
  }

  void _drawSaddle(Canvas canvas, SaddleType saddle) {
    const blankets = [
      Color(0xffca8068),
      Color(0xffddbc73),
      Color(0xffeb7a83),
      Color(0xff925dbb),
      Color(0xff77ac91),
      Color(0xffe8e5da),
      Color(0xff4faba5),
      Color(0xff6583b7),
      Color(0xff8fceec),
      Color(0xffe98744),
    ];
    final blanket = blankets[saddle.index % blankets.length];
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 35, 29, 20),
        const Radius.circular(4),
      ),
      Paint()..color = blanket,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 31, 23, 12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xff68503c),
    );
    final trim = Paint()
      ..color = const Color(0xfff9e1a0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 36, 27, 18),
        const Radius.circular(3),
      ),
      trim,
    );
    _line(
      canvas,
      const Offset(48, 43),
      const Offset(49, 58),
      const Color(0xff68503c),
      2,
    );
    canvas.drawOval(const Rect.fromLTWH(45, 55, 8, 6), trim);
    final symbol = switch (saddle.name) {
      'sky' => const Color(0xffe8fcff),
      'ember' => const Color(0xffffd44d),
      'royal' || 'jousting' => const Color(0xffffd44d),
      _ => blanket,
    };
    canvas.drawCircle(const Offset(57, 47), 3, Paint()..color = symbol);
    if (saddle.name == 'western' || saddle.name == 'jousting') {
      _line(
        canvas,
        const Offset(60, 33),
        const Offset(60, 25),
        const Color(0xff68503c),
        3,
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(this);
}
