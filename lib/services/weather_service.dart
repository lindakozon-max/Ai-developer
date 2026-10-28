import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/weather.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final endpoint = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '48.213',
    'longitude': '17.154',
    'current': 'temperature_2m,weather_code,is_day,cloud_cover,wind_speed_10m',
    'timezone': 'Europe/Bratislava',
    'forecast_days': '1',
  });

  Future<WeatherSnapshot> fetchCurrent() async {
    final response = await _client
        .get(endpoint)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Weather request failed (${response.statusCode}).');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> ||
        body['current'] is! Map<String, dynamic>) {
      throw const FormatException('Missing current weather.');
    }
    final current = body['current'] as Map<String, dynamic>;
    double number(String key) {
      final value = current[key];
      if (value is! num || !value.isFinite) {
        throw FormatException('Invalid weather field: $key');
      }
      return value.toDouble();
    }

    final code = number('weather_code');
    final day = number('is_day');
    final cloud = number('cloud_cover');
    final wind = number('wind_speed_10m');
    final time = current['time'];
    if (code != code.roundToDouble() ||
        code < 0 ||
        code > 99 ||
        (day != 0 && day != 1) ||
        cloud < 0 ||
        cloud > 100 ||
        wind < 0 ||
        time is! String ||
        DateTime.tryParse(time) == null) {
      throw const FormatException('Invalid current weather.');
    }
    return WeatherSnapshot(
      temperatureC: number('temperature_2m'),
      weatherCode: code.toInt(),
      isDay: day == 1,
      cloudCover: cloud,
      windSpeedKmh: wind,
      observedAt: DateTime.parse(time),
    );
  }

  void close() => _client.close();
}
