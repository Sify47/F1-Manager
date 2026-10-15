import 'dart:math';
import '../models/race_event.dart';
import '../models/race_state.dart';
import '../models/driver.dart';
import '../models/team.dart';

class IncidentEngine {
  final Random _random;

  IncidentEngine({int? seed}) : _random = Random(seed);

  /// Evaluate if a driver makes an error in a sector
  RaceEvent? evaluateDriverMistake({
    required Driver driver,
    required Team team,
    required CarTelemetry telemetry,
    required double trackWetness,
    required int currentLap,
    required int sector,
  }) {
    // Base mistake chance per sector is very low (~0.05%)
    double baseRisk = 0.0006;

    // Pace mode multiplier
    if (telemetry.paceMode == PaceMode.attack) baseRisk *= 2.5;
    if (telemetry.paceMode == PaceMode.push) baseRisk *= 1.4;
    if (telemetry.paceMode == PaceMode.conserve) baseRisk *= 0.4;

    // Tire wear penalty (worn tires = loss of grip & lockups)
    if (telemetry.tireWearPercentage > 0.70) {
      baseRisk += (telemetry.tireWearPercentage - 0.70) * 0.015;
    }

    // Driver composure & consistency mitigation
    double composureFactor = (100 - driver.stats.composure) / 100.0;
    baseRisk *= (0.6 + composureFactor * 0.8);

    // Weather mismatch risk
    if (trackWetness > 0.35 && telemetry.currentTire.optimalMaxRain < 0.20) {
      // Slicks on wet track! Huge spin risk
      baseRisk *= 6.0;
    }

    double roll = _random.nextDouble();
    if (roll < baseRisk) {
      // Mistake occurred! Determine severity
      double severityRoll = _random.nextDouble();
      if (severityRoll < 0.65) {
        // Minor lockup: flat spot, loses 1.2s - 2.5s
        return RaceEvent(
          id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${driver.id}',
          lap: currentLap,
          sector: sector,
          title: 'LOCKUP!',
          description: '${driver.lastName} locked up into Turn ${sector * 4}! Lost time and flat-spotted the tire.',
          severity: EventSeverity.warning,
          driverId: driver.id,
          timestamp: DateTime.now(),
        );
      } else if (severityRoll < 0.90) {
        // Run wide into gravel: loses 3.0s - 6.0s
        return RaceEvent(
          id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${driver.id}',
          lap: currentLap,
          sector: sector,
          title: 'OFF TRACK!',
          description: '${driver.lastName} lost the rear and ran wide through the gravel trap!',
          severity: EventSeverity.warning,
          driverId: driver.id,
          timestamp: DateTime.now(),
        );
      } else {
        // Crash / Spin into barrier
        return RaceEvent(
          id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${driver.id}',
          lap: currentLap,
          sector: sector,
          title: 'CRASH & DNF!',
          description: '${driver.lastName} suffered heavy contact with the barriers! Car is stranded.',
          severity: EventSeverity.critical,
          driverId: driver.id,
          timestamp: DateTime.now(),
        );
      }
    }

    return null;
  }

  /// Calculates pit stop duration in seconds, including potential human error
  PitStopResult calculatePitStopDuration({
    required Team team,
    required bool repairWing,
  }) {
    // World class base pit stop is ~2.2 - 2.6 seconds
    double gymBonus = (team.facilities.pitCrewGymLevel - 1) * 0.12; // Level 5 gives 0.48s reduction
    double baseDuration = 2.7 - gymBonus + (_random.nextDouble() * 0.3);

    // Front wing replacement adds ~9-11 seconds
    if (repairWing) {
      baseDuration += 9.5 + (_random.nextDouble() * 1.5);
    }

    // Human error chance: Level 1 gym = 12% error, Level 5 gym = 3% error
    double errorChance = 0.15 - (team.facilities.pitCrewGymLevel * 0.024);
    bool hasCrewError = _random.nextDouble() < errorChance;
    String? errorNote;

    if (hasCrewError) {
      double errorSeverity = _random.nextDouble();
      if (errorSeverity < 0.60) {
        // Minor sticky wheel nut: +2 to +4 seconds
        double delay = 2.0 + _random.nextDouble() * 2.0;
        baseDuration += delay;
        errorNote = 'Hesitation on the rear-right wheel nut (+${delay.toStringAsFixed(1)}s)';
      } else if (errorSeverity < 0.90) {
        // Stuck wheel nut: +4 to +8 seconds
        double delay = 4.5 + _random.nextDouble() * 3.5;
        baseDuration += delay;
        errorNote = 'Stuck wheel nut! Major delay in the box (+${delay.toStringAsFixed(1)}s)';
      } else {
        // Nightmare stop (Kick Sauber style!): +8 to +15 seconds
        double delay = 8.0 + _random.nextDouble() * 6.0;
        baseDuration += delay;
        errorNote = 'Cross-threaded wheel nut! Agonizing disaster in pit lane (+${delay.toStringAsFixed(1)}s)';
      }
    }

    return PitStopResult(
      durationSeconds: baseDuration,
      hasError: hasCrewError,
      errorNote: errorNote,
    );
  }
}

class PitStopResult {
  final double durationSeconds;
  final bool hasError;
  final String? errorNote;

  const PitStopResult({
    required this.durationSeconds,
    required this.hasError,
    this.errorNote,
  });
}

