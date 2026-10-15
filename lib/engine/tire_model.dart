import 'dart:math';
import '../models/tire.dart';
import '../models/race_state.dart';

class TireModel {
  /// Calculates tire wear delta for a sector based on:
  /// - Base compound wear rate
  /// - Track asphalt abrasiveness
  /// - Driver tyre management skill (0-100)
  /// - Car chassis tyre preservation (0-100)
  /// - Pace mode (Conserve reduces wear, Attack increases wear)
  /// - Track moisture vs compound suitability
  static double calculateSectorWear({
    required TireCompound compound,
    required double asphaltAbrasiveness,
    required int driverTyreManagement,
    required int carTyrePreservation,
    required PaceMode paceMode,
    required double rainIntensity,
    required double sectorLengthKm,
  }) {
    // Base wear per km
    double wearPerKm = compound.wearRatePerLap / 5.0; // Normalized for ~5km circuit

    // Pace mode multiplier
    double paceMultiplier;
    switch (paceMode) {
      case PaceMode.conserve:
        paceMultiplier = 0.60; // 40% less wear
        break;
      case PaceMode.balanced:
        paceMultiplier = 1.0;
        break;
      case PaceMode.push:
        paceMultiplier = 1.40;
        break;
      case PaceMode.attack:
        paceMultiplier = 1.95;
        break;
    }

    // Driver skill multiplier: 95 skill gives 0.82 multiplier; 80 skill gives 1.05 multiplier
    double driverFactor = 1.65 - (driverTyreManagement / 100.0) * 0.85;

    // Car chassis preservation factor: 95 gives 0.88, 85 gives 1.05
    double carFactor = 1.55 - (carTyrePreservation / 100.0) * 0.70;

    // Asphalt abrasiveness multiplier (0.15 to 0.90)
    double asphaltFactor = 0.6 + (asphaltAbrasiveness * 0.8);

    // Rain penalty: Running slicks in wet or wets on dry tarmac causes rapid graining/overheating
    double surfaceMismatchPenalty = 1.0;
    if (compound.type == TireType.soft || compound.type == TireType.medium || compound.type == TireType.hard) {
      if (rainIntensity > 0.15) {
        // Cold hydroplaning wear
        surfaceMismatchPenalty = 1.3;
      }
    } else if (compound.type == TireType.intermediate || compound.type == TireType.wet) {
      if (rainIntensity < 0.10) {
        // Inter/Wet running on dry track will shred to pieces rapidly!
        surfaceMismatchPenalty = 2.8;
      }
    }

    return wearPerKm * sectorLengthKm * paceMultiplier * driverFactor * carFactor * asphaltFactor * surfaceMismatchPenalty;
  }

  /// Calculates the lap time delta (penalty or advantage) due to tire state in seconds
  static double calculatePaceDelta({
    required TireCompound compound,
    required double currentWearPercentage,
    required double trackTemp,
    required double rainIntensity,
  }) {
    // 1. Base compound advantage (e.g. Soft is -0.9s faster than Medium)
    double compoundBase = compound.basePaceAdvantage;

    // 2. Wear degradation curve (linear initial degradation, exponential after cliff)
    double wearPenalty = 0.0;
    if (currentWearPercentage <= compound.cliffThreshold) {
      // Normal wear degradation: up to +1.8s penalty before cliff
      wearPenalty = (currentWearPercentage / compound.cliffThreshold) * 1.8;
    } else {
      // The "Cliff": Tyre performance collapses drastically!
      double cliffRatio = (currentWearPercentage - compound.cliffThreshold) / (1.0 - compound.cliffThreshold);
      wearPenalty = 1.8 + pow(cliffRatio, 2.0) * 6.5; // up to +8.3 seconds loss per lap
    }

    // 3. Thermal window penalty
    double thermalPenalty = 0.0;
    if (trackTemp < compound.optimalMinTrackTemp) {
      thermalPenalty += (compound.optimalMinTrackTemp - trackTemp) * 0.05;
    } else if (trackTemp > compound.optimalMaxTrackTemp) {
      thermalPenalty += (trackTemp - compound.optimalMaxTrackTemp) * 0.06;
    }

    // 4. Rain mismatch penalty (massive penalty for wrong tire in wet/dry)
    double rainMismatchPenalty = 0.0;
    if (rainIntensity > compound.optimalMaxRain) {
      double excessRain = rainIntensity - compound.optimalMaxRain;
      // Slicks in standing water = +8 to +20 seconds per lap, spinning risk
      rainMismatchPenalty += excessRain * 25.0;
    } else if (rainIntensity < compound.optimalMinRain) {
      double missingRain = compound.optimalMinRain - rainIntensity;
      rainMismatchPenalty += missingRain * 6.0;
    }

    return compoundBase + wearPenalty + thermalPenalty + rainMismatchPenalty;
  }
}

