class CarSetup {
  final int frontWingAngle;    // 1 (low drag) to 10 (high downforce)
  final int rearWingAngle;     // 1 to 10
  final int suspensionStiffness; // 1 (soft mechanical) to 10 (stiff)
  final int camberAngle;       // 1 to 10
  final int gearRatio;         // 1 (short acceleration) to 10 (tall top speed)

  const CarSetup({
    this.frontWingAngle = 5,
    this.rearWingAngle = 5,
    this.suspensionStiffness = 5,
    this.camberAngle = 5,
    this.gearRatio = 5,
  });

  CarSetup copyWith({
    int? frontWingAngle,
    int? rearWingAngle,
    int? suspensionStiffness,
    int? camberAngle,
    int? gearRatio,
  }) {
    return CarSetup(
      frontWingAngle: frontWingAngle ?? this.frontWingAngle,
      rearWingAngle: rearWingAngle ?? this.rearWingAngle,
      suspensionStiffness: suspensionStiffness ?? this.suspensionStiffness,
      camberAngle: camberAngle ?? this.camberAngle,
      gearRatio: gearRatio ?? this.gearRatio,
    );
  }
}

class SetupEvaluationResult {
  final double setupSatisfactionPercentage; // 0.0 to 1.0 (100% optimal)
  final double paceDeltaSeconds;            // Bonus up to -0.7s per lap
  final String frontWingFeedback;
  final String rearWingFeedback;
  final String suspensionFeedback;
  final String overallDriverQuote;
  final String practiceLapTime;
  final int sessionIndex;

  const SetupEvaluationResult({
    required this.setupSatisfactionPercentage,
    required this.paceDeltaSeconds,
    required this.frontWingFeedback,
    required this.rearWingFeedback,
    required this.suspensionFeedback,
    required this.overallDriverQuote,
    this.practiceLapTime = '1:24.000',
    this.sessionIndex = 1,
  });
}

