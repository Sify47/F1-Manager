import 'tire.dart';
import 'race_state.dart';

class StintPlan {
  final int stintNumber;
  final TireType compound;
  final int startLap;
  final int endLap; // Target pit lap
  final PaceMode recommendedPace;

  const StintPlan({
    required this.stintNumber,
    required this.compound,
    required this.startLap,
    required this.endLap,
    this.recommendedPace = PaceMode.balanced,
  });

  int get stintLengthLaps => endLap - startLap + 1;

  StintPlan copyWith({
    int? stintNumber,
    TireType? compound,
    int? startLap,
    int? endLap,
    PaceMode? recommendedPace,
  }) {
    return StintPlan(
      stintNumber: stintNumber ?? this.stintNumber,
      compound: compound ?? this.compound,
      startLap: startLap ?? this.startLap,
      endLap: endLap ?? this.endLap,
      recommendedPace: recommendedPace ?? this.recommendedPace,
    );
  }
}

class StrategyOption {
  final String id;
  final String name; // E.g., 'Strategy A: Soft -> Hard (1-Stop)'
  final String description;
  final List<StintPlan> stints;
  final double estimatedTotalRaceTimeSeconds;
  final bool isChiefStrategistPick;
  final double tireRiskScore; // 0.0 (safe) to 1.0 (high tire cliff risk)

  const StrategyOption({
    required this.id,
    required this.name,
    required this.description,
    required this.stintPlans,
    required this.estimatedTotalRaceTimeSeconds,
    this.isChiefStrategistPick = false,
    required this.tireRiskScore,
  }) : stints = stintPlans;

  final List<StintPlan> stintPlans;

  int get totalStops => stints.length - 1;
}

class DriverRaceStrategy {
  final String driverId;
  final StrategyOption chosenStrategy;
  final List<StintPlan> activeStints;
  final int currentStintIndex;
  final bool autoExecutePitStops; // If true, AI race engineer handles box calls automatically

  const DriverRaceStrategy({
    required this.driverId,
    required this.chosenStrategy,
    required this.activeStints,
    this.currentStintIndex = 0,
    this.autoExecutePitStops = false,
  });

  StintPlan? get currentStint =>
      currentStintIndex < activeStints.length ? activeStints[currentStintIndex] : null;

  StintPlan? get nextStint =>
      currentStintIndex + 1 < activeStints.length ? activeStints[currentStintIndex + 1] : null;

  DriverRaceStrategy advanceStint() {
    return copyWith(currentStintIndex: currentStintIndex + 1);
  }

  DriverRaceStrategy copyWith({
    String? driverId,
    StrategyOption? chosenStrategy,
    List<StintPlan>? activeStints,
    int? currentStintIndex,
    bool? autoExecutePitStops,
  }) {
    return DriverRaceStrategy(
      driverId: driverId ?? this.driverId,
      chosenStrategy: chosenStrategy ?? this.chosenStrategy,
      activeStints: activeStints ?? this.activeStints,
      currentStintIndex: currentStintIndex ?? this.currentStintIndex,
      autoExecutePitStops: autoExecutePitStops ?? this.autoExecutePitStops,
    );
  }
}
