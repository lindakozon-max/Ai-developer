import 'dart:async';
import 'dart:convert';

import 'package:flappy_bird/domain/weather.dart';
import 'package:flappy_bird/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, Object> current({int code = 61}) => {
    'temperature_2m': 8.5,
    'weather_code': code,
    'is_day': 0,
    'cloud_cover': 95,
    'wind_speed_10m': 16.2,
    'time': '2026-10-28T18:00',
  };

  test('queries Rača and parses current local weather', () async {
    final service = WeatherService(
      client: MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.queryParameters['latitude'], '48.213');
        expect(request.url.queryParameters['longitude'], '17.154');
        expect(request.url.queryParameters['timezone'], 'Europe/Bratislava');
        expect(
          request.url.queryParameters['current'],
          contains('weather_code'),
        );
        return http.Response(jsonEncode({'current': current()}), 200);
      }),
    );
    addTearDown(service.close);
    final weather = await service.fetchCurrent();
    expect(weather.temperatureC, 8.5);
    expect(weather.isDay, isFalse);
    expect(weather.cloudCover, 95);
    expect(weather.windSpeedKmh, 16.2);
    expect(weather.observedAt, DateTime(2026, 10, 28, 18));
    expect(weather.rain, isTrue);
  });

  test('all precipitation codes map to the matching game effect', () {
    WeatherSnapshot weather(int code) => WeatherSnapshot(
      temperatureC: 0,
      weatherCode: code,
      isDay: true,
      cloudCover: 100,
      windSpeedKmh: 0,
      observedAt: DateTime(2026),
    );
    for (final code in [
      51,
      53,
      55,
      56,
      57,
      61,
      63,
      65,
      66,
      67,
      80,
      81,
      82,
      95,
      96,
      99,
    ]) {
      expect(weather(code).rain, isTrue, reason: 'rain code $code');
    }
    for (final code in [71, 73, 75, 77, 85, 86]) {
      expect(weather(code).snow, isTrue);
      expect(weather(code).rain, isFalse);
    }
    expect(weather(45).fog, isTrue);
    expect(weather(48).fog, isTrue);
    expect(weather(95).storm, isTrue);
    expect(weather(0).condition, 'Clear');
    expect(weather(3).condition, 'Overcast');
  });

  test('invalid weather never becomes a fabricated live snapshot', () async {
    for (final body in [
      {},
      {'current': {}},
      {
        'current': {...current(), 'temperature_2m': null},
      },
      {
        'current': {...current(), 'is_day': 2},
      },
      {
        'current': {...current(), 'cloud_cover': 101},
      },
      {
        'current': {...current(), 'weather_code': 1.5},
      },
      {
        'current': {...current(), 'time': 'invalid'},
      },
    ]) {
      final service = WeatherService(
        client: MockClient((_) async => http.Response(jsonEncode(body), 200)),
      );
      await expectLater(service.fetchCurrent(), throwsFormatException);
      service.close();
    }
  });

  test('HTTP and transport failures propagate for offline display', () async {
    final failed = WeatherService(
      client: MockClient((_) async => http.Response('', 503)),
    );
    addTearDown(failed.close);
    await expectLater(failed.fetchCurrent(), throwsStateError);
    final offline = WeatherService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(offline.close);
    await expectLater(
      offline.fetchCurrent(),
      throwsA(isA<http.ClientException>()),
    );
    final timedOut = WeatherService(
      client: MockClient((_) async => throw TimeoutException('timeout')),
    );
    addTearDown(timedOut.close);
    await expectLater(
      timedOut.fetchCurrent(),
      throwsA(isA<TimeoutException>()),
    );
  });
}
