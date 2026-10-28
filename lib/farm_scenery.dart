part of 'farm_game.dart';

class EnclosureBackground extends Component with HasGameReference<FarmGame> {
  @override
  void render(Canvas canvas) {
    // Cover the old shared pasture with six separate grassy enclosures.
    canvas.drawRect(
      Rect.fromLTWH(0, game.size.y * .16, game.size.x, game.size.y),
      Paint()..color = const Color(0xffefd29a),
    );
    final fence = Paint()
      ..color = const Color(0xff936747)
      ..strokeWidth = 3;
    if (game.dragons.isNotEmpty) {
      final roost = game.enclosure(6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(roost, const Radius.circular(14)),
        Paint()..color = const Color(0xffd5c7e8),
      );
      TextPainter(
          text: const TextSpan(
            text: 'Dragon roost',
            style: TextStyle(color: Color(0xff513e67), fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout(maxWidth: roost.width)
        ..paint(canvas, Offset(roost.left + 6, roost.top + 3));
    }
    for (var index = 0; index < 6; index++) {
      final r = game.enclosure(index);
      canvas.drawRect(r, Paint()..color = const Color(0xffb9df9d));
      for (final y in [r.top + 5, r.bottom - 5]) {
        canvas.drawLine(Offset(r.left, y), Offset(r.right, y), fence);
      }
      canvas.drawLine(r.topLeft, r.bottomLeft, fence);
      canvas.drawLine(r.topRight, r.bottomRight, fence);
      for (var x = r.left; x <= r.right; x += 22) {
        for (final y in [r.top, r.bottom]) {
          canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), fence);
        }
      }
      final label = index == 5 ? 'Horses' : AnimalKind.values[index].name;
      TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xff513e32),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout(maxWidth: r.width)
        ..paint(canvas, Offset(r.left + 5, r.top + 8));
      final ball = Offset(r.right - 17, r.bottom - 17);
      canvas.drawCircle(ball, 9, Paint()..color = const Color(0xffe8927e));
      canvas.drawArc(
        Rect.fromCircle(center: ball, radius: 7),
        0,
        pi,
        false,
        Paint()
          ..color = const Color(0xfffff2dc)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawOval(
        Rect.fromLTWH(r.left + 8, r.bottom - 24, 22, 13),
        Paint()
          ..color = const Color(0xff8975bb)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }
}

class WeatherOverlay extends Component with HasGameReference<FarmGame> {
  double elapsed = 0;
  @override
  void update(double dt) {
    super.update(dt);
    elapsed = (elapsed + dt) % 1000;
  }

  @override
  void render(Canvas canvas) {
    final weather = game.weather;
    if (weather == null) return;
    final s = game.size;
    final area = Rect.fromLTWH(0, 0, s.x, s.y);
    if (!weather.isDay) {
      canvas.drawRect(area, Paint()..color = const Color(0x66312958));
    }
    if (weather.cloudCover > 30) {
      canvas.drawRect(area, Paint()..color = const Color(0x22838b98));
      for (var i = 0; i < 4; i++) {
        final x =
            (i * s.x / 3 + elapsed * weather.windSpeedKmh * .4) % (s.x + 90) -
            45;
        canvas.drawOval(
          Rect.fromLTWH(x, 18 + (i % 2) * 16, 85, 30),
          Paint()..color = const Color(0x88e4e8ec),
        );
      }
    } else if (weather.isDay) {
      canvas.drawCircle(
        Offset(s.x * .15, 40),
        19,
        Paint()..color = const Color(0xffffd261),
      );
    }
    if (weather.fog) {
      canvas.drawRect(area, Paint()..color = const Color(0x77e4e8ec));
    }
    if (weather.rain || weather.snow) {
      canvas.save();
      canvas.clipRect(area);
      final paint = Paint()
        ..color = weather.snow
            ? const Color(0xeeffffff)
            : const Color(0x9985b8df)
        ..strokeWidth = 1.5;
      for (var i = 0; i < 70; i++) {
        final x =
            (i * 53 + elapsed * (12 + weather.windSpeedKmh)) % (s.x + 20) - 10;
        final y =
            (i * 97 + elapsed * (weather.snow ? 28 : 230)) % (s.y + 20) - 10;
        if (weather.snow) {
          canvas.drawCircle(Offset(x, y), 2.5, paint);
        } else {
          canvas.drawLine(Offset(x, y), Offset(x - 3, y + 10), paint);
        }
      }
      canvas.restore();
    }
    if (weather.storm && elapsed % 7 < .12) {
      canvas.drawRect(area, Paint()..color = const Color(0x66ffffff));
    }
  }
}
