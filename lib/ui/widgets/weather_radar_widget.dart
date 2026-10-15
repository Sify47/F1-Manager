import 'package:flutter/material.dart';
import '../../engine/weather_engine.dart';
import '../theme/f1_theme.dart';

class WeatherRadarWidget extends StatelessWidget {
  final WeatherState weather;

  const WeatherRadarWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark.withValues(alpha: 0.95),
        border: Border.all(color: F1Theme.surfaceBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            weather.rainIntensity > 0.4
                ? Icons.thunderstorm
                : (weather.rainIntensity > 0.05 ? Icons.water_drop : Icons.wb_sunny),
            color: weather.rainIntensity > 0.05 ? Colors.lightBlueAccent : Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'TRACK: ${weather.trackTemperature.toStringAsFixed(0)}°C',
                    style: F1Theme.f1Mono(fontSize: 9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WET: ${(weather.trackWetness * 100).toStringAsFixed(0)}%',
                    style: F1Theme.f1Mono(
                      fontSize: 9,
                      color: weather.trackWetness > 0.3 ? Colors.lightBlueAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Mini radar forecast track
              Row(
                children: [
                  Text('15M RADAR: ', style: F1Theme.f1Display(fontSize: 8, color: Colors.grey)),
                  ...weather.radarForecast.take(8).map((pt) {
                    return Container(
                      width: 5,
                      height: 8,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: pt.rainIntensity > 0.5
                            ? Colors.blue[700]
                            : (pt.rainIntensity > 0.1 ? Colors.lightBlueAccent : Colors.grey[800]),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
