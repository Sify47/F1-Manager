import 'dart:math';

class WeatherForecastPoint {
  final int minutesFromNow;
  final double rainIntensity; // 0.0 to 1.0
  final double cloudCover;    // 0.0 to 1.0

  const WeatherForecastPoint({
    required this.minutesFromNow,
    required this.rainIntensity,
    required this.cloudCover,
  });
}

class WeatherState {
  final double rainIntensity;    // 0.0 (bone dry) to 1.0 (torrential monsoon)
  final double trackWetness;     // 0.0 (dry) to 1.0 (standing water)
  final double trackTemperature; // Celsius (e.g. 25.0 to 50.0)
  final double ambientTemperature;
  final List<WeatherForecastPoint> radarForecast; // Next 15 minutes forecast

  const WeatherState({
    required this.rainIntensity,
    required this.trackWetness,
    required this.trackTemperature,
    required this.ambientTemperature,
    required this.radarForecast,
  });

  bool get isDamp => trackWetness > 0.15 && trackWetness <= 0.45;
  bool get isWet => trackWetness > 0.45;
  bool get isMonsoon => trackWetness > 0.75;

  WeatherState copyWith({
    double? rainIntensity,
    double? trackWetness,
    double? trackTemperature,
    double? ambientTemperature,
    List<WeatherForecastPoint>? radarForecast,
  }) {
    return WeatherState(
      rainIntensity: rainIntensity ?? this.rainIntensity,
      trackWetness: trackWetness ?? this.trackWetness,
      trackTemperature: trackTemperature ?? this.trackTemperature,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      radarForecast: radarForecast ?? this.radarForecast,
    );
  }
}

class WeatherEngine {
  final double baseRainProbability;
  final double baseTrackTemp;
  WeatherState _currentState;

  WeatherEngine({
    required this.baseRainProbability,
    required this.baseTrackTemp,
    int? seed,
  })  : _currentState = _createInitialState(baseRainProbability, baseTrackTemp, Random(seed));

  WeatherState get currentState => _currentState;

  static WeatherState _createInitialState(double rainProb, double baseTemp, Random rng) {
    bool startsWithRain = rng.nextDouble() < rainProb;
    double initialRain = startsWithRain ? 0.2 + rng.nextDouble() * 0.4 : 0.0;
    double initialWetness = startsWithRain ? initialRain * 0.8 : 0.0;

    List<WeatherForecastPoint> forecast = [];
    double simRain = initialRain;
    for (int min = 1; min <= 15; min++) {
      if (rng.nextDouble() < rainProb * 0.2) {
        simRain = (simRain + (rng.nextDouble() * 0.4 - 0.15)).clamp(0.0, 1.0);
      } else if (simRain > 0.0 && rng.nextDouble() < 0.25) {
        simRain = (simRain - 0.1).clamp(0.0, 1.0);
      }
      forecast.add(WeatherForecastPoint(
        minutesFromNow: min,
        rainIntensity: simRain,
        cloudCover: (simRain * 0.8 + 0.2).clamp(0.0, 1.0),
      ));
    }

    return WeatherState(
      rainIntensity: initialRain,
      trackWetness: initialWetness,
      trackTemperature: baseTemp + (rng.nextDouble() * 4 - 2),
      ambientTemperature: baseTemp - 8.0,
      radarForecast: forecast,
    );
  }

  /// Advance weather by delta seconds
  WeatherState tick(double deltaSeconds) {
    // 1. Shift forecast if minutes elapsed
    double currentRain = _currentState.rainIntensity;
    if (_currentState.radarForecast.isNotEmpty) {
      // Gradually converge towards 1st minute forecast
      double targetRain = _currentState.radarForecast.first.rainIntensity;
      currentRain += (targetRain - currentRain) * (deltaSeconds / 60.0);
    }

    // 2. Track wetness evolution (rains accumulate water; racing cars dry the racing line)
    double wetness = _currentState.trackWetness;
    if (currentRain > 0.05) {
      wetness = (wetness + currentRain * (deltaSeconds / 120.0)).clamp(0.0, 1.0);
    } else {
      // Track drying up naturally and due to 20 hot F1 cars
      wetness = (wetness - (deltaSeconds / 180.0)).clamp(0.0, 1.0);
    }

    // 3. Track temperature changes based on rain & clouds
    double trackTemp = _currentState.trackTemperature;
    if (currentRain > 0.2) {
      trackTemp = (trackTemp - (deltaSeconds / 60.0) * 0.8).clamp(16.0, 55.0);
    } else {
      trackTemp = (trackTemp + (baseTrackTemp - trackTemp) * 0.01).clamp(16.0, 55.0);
    }

    _currentState = _currentState.copyWith(
      rainIntensity: currentRain.clamp(0.0, 1.0),
      trackWetness: wetness,
      trackTemperature: trackTemp,
    );

    return _currentState;
  }
}
