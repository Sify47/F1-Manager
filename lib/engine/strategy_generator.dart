import '../models/circuit.dart';
import '../models/tire.dart';
import '../models/race_strategy_plan.dart';
import '../models/race_state.dart';

class StrategyGenerator {
  /// Generates 3 realistic strategy proposals from the Chief Race Strategist
  static List<StrategyOption> generateStrategies(Circuit circuit) {
    int totalLaps = circuit.totalLaps;
    double abrasiveness = circuit.asphaltAbrasiveness;

    List<StrategyOption> options = [];

    // --- STRATEGY A: THE STANDARD 1-STOP (Medium -> Hard) ---
    // Pit around 38-42% race distance
    int pitLap1Stop = (totalLaps * 0.40).round();
    options.add(StrategyOption(
      id: 'strat_1stop_med_hard',
      name: 'Strategy A: 1-Stop (Medium → Hard)',
      description: 'The optimal balanced strategy. Strong start on Mediums, long endurance on durable Hards.',
      isChiefStrategistPick: abrasiveness <= 0.75, // Recommended on medium/low wear circuits
      tireRiskScore: abrasiveness > 0.80 ? 0.75 : 0.25,
      estimatedTotalRaceTimeSeconds: totalLaps * circuit.baseLapRecordSeconds + circuit.pitLaneLossSeconds + 2.5,
      stintPlans: [
        StintPlan(
          stintNumber: 1,
          compound: TireType.medium,
          startLap: 1,
          endLap: pitLap1Stop,
          recommendedPace: PaceMode.balanced,
        ),
        StintPlan(
          stintNumber: 2,
          compound: TireType.hard,
          startLap: pitLap1Stop + 1,
          endLap: totalLaps,
          recommendedPace: PaceMode.balanced,
        ),
      ],
    ));

    // --- STRATEGY B: AGGRESSIVE 2-STOP (Soft -> Medium -> Soft / Hard) ---
    // Two shorter stints at high pace
    int pit1TwoStop = (totalLaps * 0.30).round();
    int pit2TwoStop = (totalLaps * 0.65).round();
    TireType finalCompound = abrasiveness > 0.80 ? TireType.medium : TireType.soft;

    options.add(StrategyOption(
      id: 'strat_2stop_soft_med',
      name: 'Strategy B: 2-Stop (Soft → Medium → ${finalCompound == TireType.soft ? "Soft" : "Medium"})',
      description: 'Maximum attack speed! Lightning start off the line on Softs with early undercut power.',
      isChiefStrategistPick: abrasiveness > 0.75, // Recommended on high abrasiveness circuits (Bahrain/Silverstone)
      tireRiskScore: 0.20, // Low tire wear risk since stints are short
      estimatedTotalRaceTimeSeconds: (totalLaps * (circuit.baseLapRecordSeconds - 0.7)) + (circuit.pitLaneLossSeconds + 2.5) * 2,
      stintPlans: [
        StintPlan(
          stintNumber: 1,
          compound: TireType.soft,
          startLap: 1,
          endLap: pit1TwoStop,
          recommendedPace: PaceMode.push,
        ),
        StintPlan(
          stintNumber: 2,
          compound: TireType.medium,
          startLap: pit1TwoStop + 1,
          endLap: pit2TwoStop,
          recommendedPace: PaceMode.push,
        ),
        StintPlan(
          stintNumber: 3,
          compound: finalCompound,
          startLap: pit2TwoStop + 1,
          endLap: totalLaps,
          recommendedPace: PaceMode.attack,
        ),
      ],
    ));

    // --- STRATEGY C: THE REVERSE OVERCUT GAMBLE (Hard -> Soft / Medium) ---
    int pitLapReverse = (totalLaps * 0.60).round();
    options.add(StrategyOption(
      id: 'strat_reverse_hard_soft',
      name: 'Strategy C: Reverse 1-Stop (Hard → Soft)',
      description: 'Overcut gamble. Run long in clean air, praying for a mid-race Safety Car, then unleash fresh Softs.',
      isChiefStrategistPick: false,
      tireRiskScore: 0.40,
      estimatedTotalRaceTimeSeconds: (totalLaps * (circuit.baseLapRecordSeconds + 0.3)) + circuit.pitLaneLossSeconds + 2.5,
      stintPlans: [
        StintPlan(
          stintNumber: 1,
          compound: TireType.hard,
          startLap: 1,
          endLap: pitLapReverse,
          recommendedPace: PaceMode.conserve,
        ),
        StintPlan(
          stintNumber: 2,
          compound: TireType.soft,
          startLap: pitLapReverse + 1,
          endLap: totalLaps,
          recommendedPace: PaceMode.attack,
        ),
      ],
    ));

    return options;
  }

  /// Create a customized 1-Stop strategy based on player choices
  static StrategyOption createCustom1Stop({
    required Circuit circuit,
    required TireType compound1,
    required TireType compound2,
    required int pitLap,
  }) {
    int totalLaps = circuit.totalLaps;
    int safePitLap = pitLap.clamp(3, totalLaps - 3);

    return StrategyOption(
      id: 'custom_1stop_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom 1-Stop (${_compoundName(compound1)} → ${_compoundName(compound2)})',
      description: 'Custom Pit Strategy: Box on Lap $safePitLap for ${_compoundName(compound2)}s.',
      isChiefStrategistPick: false,
      tireRiskScore: (safePitLap > totalLaps * 0.65) ? 0.65 : 0.30,
      estimatedTotalRaceTimeSeconds: totalLaps * circuit.baseLapRecordSeconds + circuit.pitLaneLossSeconds + 2.5,
      stintPlans: [
        StintPlan(
          stintNumber: 1,
          compound: compound1,
          startLap: 1,
          endLap: safePitLap,
          recommendedPace: PaceMode.balanced,
        ),
        StintPlan(
          stintNumber: 2,
          compound: compound2,
          startLap: safePitLap + 1,
          endLap: totalLaps,
          recommendedPace: PaceMode.balanced,
        ),
      ],
    );
  }

  /// Create a customized 2-Stop strategy based on player choices
  static StrategyOption createCustom2Stop({
    required Circuit circuit,
    required TireType compound1,
    required TireType compound2,
    required TireType compound3,
    required int pitLap1,
    required int pitLap2,
  }) {
    int totalLaps = circuit.totalLaps;
    int safePit1 = pitLap1.clamp(2, totalLaps - 5);
    int safePit2 = pitLap2.clamp(safePit1 + 2, totalLaps - 2);

    return StrategyOption(
      id: 'custom_2stop_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom 2-Stop (${_compoundName(compound1)} → ${_compoundName(compound2)} → ${_compoundName(compound3)})',
      description: 'Custom 2-Stop: Box on Lap $safePit1 and Lap $safePit2.',
      isChiefStrategistPick: false,
      tireRiskScore: 0.20,
      estimatedTotalRaceTimeSeconds: (totalLaps * (circuit.baseLapRecordSeconds - 0.5)) + (circuit.pitLaneLossSeconds + 2.5) * 2,
      stintPlans: [
        StintPlan(
          stintNumber: 1,
          compound: compound1,
          startLap: 1,
          endLap: safePit1,
          recommendedPace: PaceMode.push,
        ),
        StintPlan(
          stintNumber: 2,
          compound: compound2,
          startLap: safePit1 + 1,
          endLap: safePit2,
          recommendedPace: PaceMode.balanced,
        ),
        StintPlan(
          stintNumber: 3,
          compound: compound3,
          startLap: safePit2 + 1,
          endLap: totalLaps,
          recommendedPace: PaceMode.attack,
        ),
      ],
    );
  }

  /// Assigns diverse realistic strategies across the whole grid
  static Map<String, DriverRaceStrategy> assignGridStrategies({
    required Circuit circuit,
    required List<String> startingGridDriverIds,
    Map<String, DriverRaceStrategy>? playerStrategies,
  }) {
    final defaultOptions = generateStrategies(circuit);
    final stratA = defaultOptions[0]; // 1-Stop Med -> Hard
    final stratB = defaultOptions[1]; // 2-Stop Soft -> Med -> Soft/Hard
    final stratC = defaultOptions[2]; // Reverse Hard -> Soft

    final Map<String, DriverRaceStrategy> gridStrategies = {};

    for (int i = 0; i < startingGridDriverIds.length; i++) {
      String driverId = startingGridDriverIds[i];

      // If player already specified strategy, keep it
      if (playerStrategies != null && playerStrategies.containsKey(driverId)) {
        gridStrategies[driverId] = playerStrategies[driverId]!;
        continue;
      }

      // AI Strategy Distribution based on grid position & track abrasiveness:
      // Front-runners (P1-P6): 70% Strategy A (Conservative/Safe track position), 30% Strategy B (Sprint)
      // Midfield (P7-P14): Mixed (A or B)
      // Backmarkers (P15-P20): Often try Strategy C (Reverse hard tyre gamble for Safety Car overcut!)
      StrategyOption chosen;
      if (i >= 15 && (i % 2 == 1)) {
        chosen = stratC;
      } else if (circuit.asphaltAbrasiveness > 0.75) {
        chosen = (i % 3 == 0) ? stratA : stratB;
      } else {
        chosen = (i % 4 == 0) ? stratB : stratA;
      }

      gridStrategies[driverId] = DriverRaceStrategy(
        driverId: driverId,
        chosenStrategy: chosen,
        activeStints: List.from(chosen.stints),
        currentStintIndex: 0,
        autoExecutePitStops: true, // Rivals are AI controlled
      );
    }

    return gridStrategies;
  }

  static String _compoundName(TireType type) {
    switch (type) {
      case TireType.soft:
        return 'Soft';
      case TireType.medium:
        return 'Medium';
      case TireType.hard:
        return 'Hard';
      case TireType.intermediate:
        return 'Intermediate';
      case TireType.wet:
        return 'Wet';
    }
  }
}
