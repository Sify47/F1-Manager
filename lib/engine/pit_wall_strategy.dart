import '../models/race_state.dart';
import '../models/circuit.dart';
import '../models/race_event.dart';

class UndercutPrediction {
  final String targetDriverId;
  final String targetDriverName;
  final double predictedExitGapSeconds; // Positive = will exit ahead, Negative = will exit behind
  final bool willExitAhead;
  final int predictedExitPosition;
  final String analysisText;

  const UndercutPrediction({
    required this.targetDriverId,
    required this.targetDriverName,
    required this.predictedExitGapSeconds,
    required this.willExitAhead,
    required this.predictedExitPosition,
    required this.analysisText,
  });
}

class PitWallStrategy {
  /// Predicts the track position and gap to target rivals if the car pits on this lap
  static UndercutPrediction calculateUndercut({
    required CarTelemetry pittingCar,
    required List<CarTelemetry> allCars,
    required Circuit circuit,
    required double estimatedPitStopDuration, // typically 2.5s stationary
    required SafetyCarStatus safetyCarStatus,
  }) {
    // Total time lost for pitting:
    // Under Green Flag: full pit lane delta + stationary time
    // Under VSC: ~40% time loss reduction
    // Under SC: ~55% time loss reduction (cheap pit stop window!)
    double pitLoss = circuit.pitLaneLossSeconds + estimatedPitStopDuration;
    if (safetyCarStatus == SafetyCarStatus.virtualSafetyCar) {
      pitLoss *= 0.60;
    } else if (safetyCarStatus == SafetyCarStatus.fullSafetyCar) {
      pitLoss *= 0.45;
    }

    // Pitting car will lose `pitLoss` seconds relative to cars on track
    double projectedGapToLeader = pittingCar.gapToLeaderSeconds + pitLoss;

    // Determine predicted position among active cars
    int predictedPos = 1;
    String rivalAheadName = 'Leader';
    double bestRivalDelta = 999.0;

    for (var car in allCars) {
      if (car.driverId == pittingCar.driverId || car.status == CarRaceStatus.outOfRace) continue;
      if (car.gapToLeaderSeconds < projectedGapToLeader) {
        predictedPos++;
        double delta = projectedGapToLeader - car.gapToLeaderSeconds;
        if (delta < bestRivalDelta) {
          bestRivalDelta = delta;
          rivalAheadName = car.driverId;
        }
      }
    }

    bool isCheapStop = safetyCarStatus != SafetyCarStatus.clear;
    String analysis;
    if (isCheapStop) {
      analysis = 'CHEAP PIT WINDOW! Pitting under ${safetyCarStatus == SafetyCarStatus.virtualSafetyCar ? "VSC" : "Safety Car"} saves ~${(pitLoss * 0.7).toStringAsFixed(1)}s!';
    } else if (predictedPos <= pittingCar.position) {
      analysis = 'Clean pit exit into open air! Excellent undercut opportunity.';
    } else {
      analysis = 'Risk of exiting into heavy traffic behind P${predictedPos - 1}.';
    }

    return UndercutPrediction(
      targetDriverId: rivalAheadName,
      targetDriverName: rivalAheadName,
      predictedExitGapSeconds: bestRivalDelta,
      willExitAhead: predictedPos <= pittingCar.position,
      predictedExitPosition: predictedPos,
      analysisText: analysis,
    );
  }
}
