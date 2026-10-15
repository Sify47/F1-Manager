import 'dart:math';
import '../models/car_setup.dart';
import '../models/circuit.dart';
import '../models/driver.dart';

class SetupEngine {
  /// Evaluates a car setup against circuit characteristics and generates driver feedback
  static SetupEvaluationResult evaluateSetup({
    required CarSetup setup,
    required Circuit circuit,
    Driver? driver,
    int sessionIndex = 1, // 1: FP1, 2: FP2, 3: FP3
  }) {
    // 1. Determine circuit optimal target values
    int targetFrontWing;
    int targetRearWing;
    int targetSuspension;
    int targetGearRatio;

    if (circuit.id == 'monaco') {
      targetFrontWing = 10;
      targetRearWing = 10;
      targetSuspension = 2; // Very soft for bumps & kerbs
      targetGearRatio = 2;  // Short gears for traction
    } else if (circuit.id == 'monza') {
      targetFrontWing = 2;
      targetRearWing = 2;
      targetSuspension = 9; // Very stiff for high speed direction change
      targetGearRatio = 9;  // Maximum top speed
    } else if (circuit.id == 'spa' || circuit.id == 'silverstone') {
      targetFrontWing = 7;
      targetRearWing = 7;
      targetSuspension = 8;
      targetGearRatio = 7;
    } else if (circuit.id == 'bahrain' || circuit.id == 'interlagos') {
      targetFrontWing = 6;
      targetRearWing = 6;
      targetSuspension = 6;
      targetGearRatio = 6;
    } else {
      targetFrontWing = 5;
      targetRearWing = 5;
      targetSuspension = 5;
      targetGearRatio = 5;
    }

    // Driver individual preference adjustments
    if (driver != null) {
      if (driver.stats.corneringFast >= 92) {
        targetFrontWing = (targetFrontWing + 1).clamp(1, 10);
      }
      if (driver.stats.braking >= 94) {
        targetSuspension = (targetSuspension + 1).clamp(1, 10);
      }
    }

    // 2. Compute deviation penalties
    int diffFront = (setup.frontWingAngle - targetFrontWing).abs();
    int diffRear = (setup.rearWingAngle - targetRearWing).abs();
    int diffSusp = (setup.suspensionStiffness - targetSuspension).abs();
    int diffGear = (setup.gearRatio - targetGearRatio).abs();

    int totalDiff = diffFront + diffRear + diffSusp + diffGear;
    // Max possible diff is around ~36
    double satisfaction = max(0.0, 1.0 - (totalDiff / 24.0)).clamp(0.20, 1.0);

    // Pace delta bonus (up to -0.7s per lap for 100% setup)
    double paceBonus = -0.7 * (satisfaction - 0.5);

    // Track Evolution based on Session (FP1 -> FP2 -> FP3)
    double trackEvoOffset = sessionIndex == 1 ? 0.80 : (sessionIndex == 2 ? 0.35 : 0.0);
    double driverSkillDiscount = driver != null ? (driver.stats.overallRating - 80) * 0.02 : 0.0;
    double simulatedLapSeconds = circuit.baseLapRecordSeconds + trackEvoOffset - paceBonus - driverSkillDiscount + ((1.0 - satisfaction) * 1.6);

    int mins = simulatedLapSeconds ~/ 60;
    double secs = simulatedLapSeconds % 60;
    String formattedLapTime = '$mins:${secs.toStringAsFixed(3).padLeft(6, '0')}';

    // 3. Driver diagnostic feedback
    String fwFeedback;
    if (setup.frontWingAngle < targetFrontWing - 1) {
      fwFeedback = 'Too much understeer! The front end won\'t bite on turn-in.';
    } else if (setup.frontWingAngle > targetFrontWing + 1) {
      fwFeedback = 'Rear instability! Car is snapping oversteer into braking.';
    } else {
      fwFeedback = 'Front wing balance feels dialed in.';
    }

    String rwFeedback;
    if (setup.rearWingAngle < targetRearWing - 1) {
      rwFeedback = 'Lacking rear downforce in the fast sweepers. Need more wing.';
    } else if (setup.rearWingAngle > targetRearWing + 1) {
      rwFeedback = 'Dragging too much down the straights. Rear wing is too steep.';
    } else {
      rwFeedback = 'Rear grip is solid on corner exits.';
    }

    String suspFeedback;
    if (setup.suspensionStiffness < targetSuspension - 1) {
      suspFeedback = 'Car feels too boaty and sluggish during quick chicane transitions.';
    } else if (setup.suspensionStiffness > targetSuspension + 1) {
      suspFeedback = 'Suspension is way too stiff! We are skipping over kerbs violently.';
    } else {
      suspFeedback = 'Mechanical kerb ride is compliant and balanced.';
    }

    String quote;
    String dName = driver?.lastName ?? 'Driver';
    if (satisfaction > 0.90) {
      quote = '"$dName: The car is on absolute rails! Best balance of the weekend!"';
    } else if (satisfaction > 0.70) {
      quote = '"$dName: Pretty decent baseline for FP$sessionIndex. A few clicks more fine-tuning and we\'re flying."';
    } else {
      quote = '"$dName: We are fighting the car in every corner in FP$sessionIndex. We need changes before the next session!"';
    }

    return SetupEvaluationResult(
      setupSatisfactionPercentage: satisfaction,
      paceDeltaSeconds: paceBonus,
      frontWingFeedback: fwFeedback,
      rearWingFeedback: rwFeedback,
      suspensionFeedback: suspFeedback,
      overallDriverQuote: quote,
      practiceLapTime: formattedLapTime,
      sessionIndex: sessionIndex,
    );
  }
}

