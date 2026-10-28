part of 'farm_game.dart';

/// Small decorations sit on the paths, leaving the pen centers free for animals.
class FarmPurchases extends Component with HasGameReference<FarmGame> {
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time = (_time + dt) % 1000;
  }

  @override
  void render(Canvas canvas) {
    if (game.size.x <= 0 || game.size.y <= 0) return;
    final scale = min(1.0, game.size.x / 480);
    for (final item in game.ownedPurchases) {
      canvas.save();
      if (item == FarmItem.dragon) {
        canvas.translate(
          game.size.x * (.22 + sin(_time * .35) * .10),
          game.size.y * .105 + sin(_time * 2) * 4,
        );
        canvas.scale(scale);
        _drawDragon(canvas);
      } else {
        final slot = item.index - 1;
        final x =
            game.size.x *
            (slot >= 6 ? .5 + (slot % 3) * .2 : .25 + (slot % 3) * .25);
        final y = game.size.y * (.435 + (slot ~/ 3) * .25);
        canvas.translate(x, y);
        canvas.scale(scale);
        _drawItem(canvas, item);
      }
      canvas.restore();
    }
  }

  Paint _paint(Color color) => Paint()..color = color;
  static const _wood = Color(0xff97633e);
  static const _green = Color(0xff69ac65);
  static const _water = Color(0xff70c3df);

  void _drawItem(Canvas c, FarmItem item) {
    switch (item) {
      case FarmItem.fountain:
        c.drawOval(
          const Rect.fromLTWH(-19, -4, 38, 12),
          _paint(const Color(0xffb1b5c4)),
        );
        c.drawOval(const Rect.fromLTWH(-15, -4, 30, 7), _paint(_water));
        _line(c, const Offset(0, 0), const Offset(0, -20), _water, 4);
        for (final side in [-1.0, 1.0]) {
          c.drawPath(
            Path()
              ..moveTo(0, -20)
              ..quadraticBezierTo(side * 15, -24, side * 12, -5),
            Paint()
              ..color = _water
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      case FarmItem.windmill:
        c.drawPath(
          Path()
            ..moveTo(-9, 8)
            ..lineTo(-5, -23)
            ..lineTo(5, -23)
            ..lineTo(9, 8)
            ..close(),
          _paint(const Color(0xffe6d4ac)),
        );
        c.save();
        c.translate(0, -20);
        c.rotate(_time * .7);
        for (var blade = 0; blade < 4; blade++) {
          c.rotate(pi / 2);
          c.drawRect(const Rect.fromLTWH(0, -3, 18, 6), _paint(_wood));
        }
        c.restore();
        c.drawCircle(const Offset(0, -20), 3, _paint(const Color(0xffffdb79)));
      case FarmItem.flowerBed:
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-20, -4, 40, 12),
            const Radius.circular(4),
          ),
          _paint(_wood),
        );
        for (var i = 0; i < 4; i++) {
          final x = -14.0 + i * 9;
          _line(c, Offset(x, 0), Offset(x, -10), _green, 2);
          _flower(
            c,
            Offset(x, -10),
            i.isEven ? const Color(0xffed91ab) : const Color(0xffa88fe2),
          );
        }
      case FarmItem.appleTree:
        _line(c, const Offset(0, 7), const Offset(0, -20), _wood, 6);
        c.drawCircle(const Offset(0, -20), 16, _paint(_green));
        for (final apple in [
          const Offset(-8, -22),
          const Offset(7, -15),
          const Offset(3, -28),
        ]) {
          c.drawCircle(apple, 3.5, _paint(const Color(0xffe16a68)));
        }
      case FarmItem.lanterns:
        _line(c, const Offset(-18, 8), const Offset(-18, -24), _wood, 2);
        _line(c, const Offset(18, 8), const Offset(18, -24), _wood, 2);
        _line(c, const Offset(-18, -24), const Offset(18, -24), _wood, 1);
        for (final x in [-11.0, 0.0, 11.0]) {
          c.drawCircle(
            Offset(x, -15),
            9 + sin(_time * 2) * 1.5,
            _paint(const Color(0x33ffda72)),
          );
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 4, -21, 8, 11),
              const Radius.circular(3),
            ),
            _paint(const Color(0xffffcf69)),
          );
        }
      case FarmItem.picnicTable:
        _line(c, const Offset(-10, -3), const Offset(-15, 9), _wood, 4);
        _line(c, const Offset(10, -3), const Offset(15, 9), _wood, 4);
        c.drawRect(const Rect.fromLTWH(-21, -12, 42, 8), _paint(_wood));
        c.drawRect(
          const Rect.fromLTWH(-11, -12, 22, 8),
          _paint(const Color(0xffedb6a4)),
        );
        c.drawRect(const Rect.fromLTWH(-23, 0, 46, 4), _paint(_wood));
      case FarmItem.hayCart:
        c.drawRect(const Rect.fromLTWH(-19, -9, 35, 14), _paint(_wood));
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-15, -23, 27, 16),
            const Radius.circular(4),
          ),
          _paint(const Color(0xffe5c365)),
        );
        _line(c, const Offset(-5, -23), const Offset(-5, -7), _wood, 2);
        for (final x in [-11.0, 9.0]) {
          c.drawCircle(Offset(x, 6), 5, _paint(const Color(0xff64514a)));
        }
        _line(c, const Offset(16, -2), const Offset(26, -8), _wood, 3);
      case FarmItem.duckPond:
        c.drawOval(
          const Rect.fromLTWH(-24, -12, 48, 23),
          _paint(const Color(0xff9cbf80)),
        );
        c.drawOval(const Rect.fromLTWH(-20, -10, 40, 18), _paint(_water));
        final x = sin(_time) * 7;
        c.drawOval(
          Rect.fromLTWH(x - 7, -7, 13, 8),
          _paint(const Color(0xffffdc7a)),
        );
        c.drawCircle(Offset(x + 5, -9), 4, _paint(const Color(0xffffdc7a)));
        _line(
          c,
          Offset(x + 8, -8),
          Offset(x + 12, -8),
          const Color(0xffdf9b4b),
          2,
        );
      case FarmItem.butterflyGarden:
        c.drawOval(const Rect.fromLTWH(-23, -5, 46, 14), _paint(_green));
        for (final x in [-12.0, 0.0, 12.0]) {
          _flower(c, Offset(x, -6), const Color(0xffb18add));
          final center = Offset(
            x + sin(_time + x) * 4,
            -20 + cos(_time * 2 + x) * 3,
          );
          final spread = 2 + sin(_time * 9).abs() * 3;
          c.drawOval(
            Rect.fromCenter(
              center: center - const Offset(3, 0),
              width: spread,
              height: 8,
            ),
            _paint(const Color(0xfff5a76d)),
          );
          c.drawOval(
            Rect.fromCenter(
              center: center + const Offset(3, 0),
              width: spread,
              height: 8,
            ),
            _paint(const Color(0xfff5a76d)),
          );
          _line(
            c,
            center - const Offset(0, 3),
            center + const Offset(0, 3),
            _wood,
            1,
          );
        }
      case FarmItem.dragon:
        break;
    }
  }

  void _flower(Canvas c, Offset center, Color color) {
    for (var petal = 0; petal < 5; petal++) {
      c.drawCircle(
        center + Offset(cos(petal * pi * .4), sin(petal * pi * .4)) * 3,
        2.7,
        _paint(color),
      );
    }
    c.drawCircle(center, 2, _paint(const Color(0xffffdf79)));
  }

  void _drawDragon(Canvas c) {
    const body = Color(0xff8f75c4);
    const wing = Color(0xffcaa1db);
    final flap = sin(_time * 7) * 10;
    c.drawPath(
      Path()
        ..moveTo(-8, 0)
        ..quadraticBezierTo(-32, -5, -36, 12)
        ..quadraticBezierTo(-22, 6, -10, 13)
        ..close(),
      _paint(body),
    );
    for (final side in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(2, 0)
          ..lineTo(side * 29, -24 + flap)
          ..lineTo(side * 25, -7 + flap)
          ..lineTo(side * 13, -9)
          ..lineTo(side * 12, 6)
          ..close(),
        _paint(wing),
      );
    }
    c.drawOval(const Rect.fromLTWH(-17, -4, 39, 24), _paint(body));
    c.drawOval(
      const Rect.fromLTWH(-7, 4, 20, 13),
      _paint(const Color(0xffeccea1)),
    );
    c.drawCircle(const Offset(23, -6), 13, _paint(body));
    c.drawOval(const Rect.fromLTWH(25, -4, 17, 10), _paint(body));
    for (final x in [16.0, 28.0]) {
      c.drawPath(
        Path()
          ..moveTo(x - 3, -15)
          ..lineTo(x, -26)
          ..lineTo(x + 3, -15)
          ..close(),
        _paint(const Color(0xffffdb79)),
      );
    }
    c.drawCircle(const Offset(27, -9), 3, _paint(const Color(0xffffffff)));
    c.drawCircle(const Offset(28, -9), 1.6, _paint(const Color(0xff42374e)));
    c.drawCircle(const Offset(37, -1), 1, _paint(const Color(0xff42374e)));
    _line(c, const Offset(-6, 15), const Offset(-9, 22), body, 5);
    _line(c, const Offset(13, 15), const Offset(17, 21), body, 5);
  }
}
