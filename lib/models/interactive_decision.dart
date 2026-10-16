import 'tire.dart';
import 'race_state.dart';

enum DecisionType {
  tyreCrisis,         // Blistering or extreme wear cliff
  weatherGamble,       // Sudden rain or drying track crossover
  teammateConflict,    // Faster teammate stuck behind slower one
  overtakeOpportunity, // Divebomb inside line vs save tyres
  safetyCarWindow,     // Cheap pit stop under SC vs track position
  mechanicalGlitch,    // Engine/brake overheating
}

enum DecisionActionType {
  boxImmediately,
  stayOutAndPush,
  liftAndCoast,
  swapTeammates,
  holdPositions,
  attackWithErs,
  defendAggressive,
}

class DecisionOption {
  final String id;
  final String title;
  final String description;
  final String pros;
  final String cons;
  final DecisionActionType actionType;
  final TireType? targetCompound;
  final PaceMode? targetPace;
  final ErsMode? targetErs;

  const DecisionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.pros,
    required this.cons,
    required this.actionType,
    this.targetCompound,
    this.targetPace,
    this.targetErs,
  });
}

class InteractiveDecision {
  final String id;
  final int lap;
  final int sector;
  final String driverId;
  final String driverShortName;
  final String headline;
  final String radioSnippet;
  final String situationDetail;
  final DecisionType type;
  final List<DecisionOption> options;
  final DateTime timestamp;

  const InteractiveDecision({
    required this.id,
    required this.lap,
    required this.sector,
    required this.driverId,
    required this.driverShortName,
    required this.headline,
    required this.radioSnippet,
    required this.situationDetail,
    required this.type,
    required this.options,
    required this.timestamp,
  });
}

enum TeamOrderType {
  swapPositions,
  holdPositions,
  letTeammatesRace,
}

