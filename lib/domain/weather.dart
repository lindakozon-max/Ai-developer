/// Current modelled weather for Bratislava–Rača from Open-Meteo.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureC,
    required this.weatherCode,
    required this.isDay,
    required this.cloudCover,
    required this.windSpeedKmh,
    required this.observedAt,
  });

  final double temperatureC;
  final int weatherCode;
  final bool isDay;
  final double cloudCover;
  final double windSpeedKmh;

  /// Local observation time in Europe/Bratislava, as supplied by the API.
  final DateTime observedAt;

  bool get storm => weatherCode >= 95;
  bool get snow => const [71, 73, 75, 77, 85, 86].contains(weatherCode);
  bool get fog => weatherCode == 45 || weatherCode == 48;
  bool get rain =>
      storm ||
      const [
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
      ].contains(weatherCode);
  String get condition {
    if (storm) return 'Thunderstorm';
    if (snow) return 'Snow';
    if (rain) return 'Rain';
    if (fog) return 'Fog';
    return switch (weatherCode) {
      0 => 'Clear',
      1 => 'Mostly clear',
      2 => 'Partly cloudy',
      3 => 'Overcast',
      _ => 'Unknown conditions',
    };
  }
}
