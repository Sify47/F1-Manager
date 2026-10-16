import 'team.dart';
import 'circuit.dart';
import '../state/career_controller.dart';
import '../data/teams_data.dart';

enum ObjectiveCategory {
  boardExpectation,  // Mandatory expectation from team owners
  sponsorBounty,     // Optional high-paying sponsor challenge
  rivalryShootout,   // Direct head-to-head with closest rival team
  tacticalMastery,   // Strategic stint or tire management challenge
}

enum ObjectiveType {
  finishPosition,
  bothCarsInPoints,
  beatTeammate,
  oneStopStrategy,
  tyreStintLength,
  outscoreRivalTeam,
  reachQualiQ3,
  cleanRaceNoDnf,
}

class BoardObjective {
  final String id;
  final String title;
  final String description;
  final ObjectiveCategory category;
  final ObjectiveType type;
  final int targetValue; // e.g. 5 for P5, 20 for 20 laps stint
  final String? targetRivalTeamId;
  final int rewardMillions;
  final int confidenceBonus;
  final int confidencePenalty;
  final bool isAchieved;
  final bool isEvaluated;

  const BoardObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.targetValue,
    this.targetRivalTeamId,
    required this.rewardMillions,
    required this.confidenceBonus,
    required this.confidencePenalty,
    this.isAchieved = false,
    this.isEvaluated = false,
  });

  BoardObjective copyWith({
    bool? isAchieved,
    bool? isEvaluated,
  }) {
    return BoardObjective(
      id: id,
      title: title,
      description: description,
      category: category,
      type: type,
      targetValue: targetValue,
      targetRivalTeamId: targetRivalTeamId,
      rewardMillions: rewardMillions,
      confidenceBonus: confidenceBonus,
      confidencePenalty: confidencePenalty,
      isAchieved: isAchieved ?? this.isAchieved,
      isEvaluated: isEvaluated ?? this.isEvaluated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'type': type.index,
        'targetValue': targetValue,
        'targetRivalTeamId': targetRivalTeamId,
        'rewardMillions': rewardMillions,
        'confidenceBonus': confidenceBonus,
        'confidencePenalty': confidencePenalty,
        'isAchieved': isAchieved,
        'isEvaluated': isEvaluated,
      };
}

class BoardObjectiveGenerator {
  static List<BoardObjective> generateWeekendObjectives({
    required Team team,
    required Circuit circuit,
    required int raceIndex,
    required List<ChampionshipStanding> constructorStandings,
  }) {
    final List<BoardObjective> objectives = [];
    final int carOvr = team.car.overallRating;

    // 1. Primary Board Expectation based on Car Performance Tier
    if (carOvr >= 86) {
      // Top Tier: Red Bull, Ferrari, McLaren, Mercedes
      objectives.add(
        const BoardObjective(
          id: 'obj_primary_top',
          title: 'Podium Finish Mandate',
          description: 'The board expects at least one car on the podium (P3 or higher).',
          category: ObjectiveCategory.boardExpectation,
          type: ObjectiveType.finishPosition,
          targetValue: 3,
          rewardMillions: 4,
          confidenceBonus: 10,
          confidencePenalty: 12,
        ),
      );
    } else if (carOvr >= 78) {
      // Midfield Tier: Aston Martin, Alpine, RB
      objectives.add(
        const BoardObjective(
          id: 'obj_primary_mid',
          title: 'Top 8 Points Target',
          description: 'Secure valuable championship points by finishing P8 or higher.',
          category: ObjectiveCategory.boardExpectation,
          type: ObjectiveType.finishPosition,
          targetValue: 8,
          rewardMillions: 3,
          confidenceBonus: 12,
          confidencePenalty: 8,
        ),
      );
    } else {
      // Backmarker Tier: Williams, Stake, Haas
      objectives.add(
        const BoardObjective(
          id: 'obj_primary_back',
          title: 'Target P12 or Points Miracle',
          description: 'Maximize race opportunities and finish P12 or higher.',
          category: ObjectiveCategory.boardExpectation,
          type: ObjectiveType.finishPosition,
          targetValue: 12,
          rewardMillions: 3,
          confidenceBonus: 15,
          confidencePenalty: 6,
        ),
      );
    }

    // 2. Rivalry Shootout
    String rivalTeamId = _findClosestRival(team.id, constructorStandings);
    Team? rivalTeam = TeamsData.getTeamById(rivalTeamId);
    String rivalName = rivalTeam?.name ?? 'Main Rival';

    objectives.add(
      BoardObjective(
        id: 'obj_rival_${rivalTeamId}_$raceIndex',
        title: 'Constructor Rivalry: $rivalName',
        description: 'Outscore $rivalName in total constructor points this Grand Prix.',
        category: ObjectiveCategory.rivalryShootout,
        type: ObjectiveType.outscoreRivalTeam,
        targetValue: 0,
        targetRivalTeamId: rivalTeamId,
        rewardMillions: 3,
        confidenceBonus: 8,
        confidencePenalty: 6,
      ),
    );

    // 3. Tactical Mastery / Sponsor Challenge
    if (raceIndex % 2 == 0) {
      objectives.add(
        const BoardObjective(
          id: 'obj_tactical_stint',
          title: 'Tyre Management Masterclass',
          description: 'Execute a disciplined strategy with at least one 18+ lap stint.',
          category: ObjectiveCategory.tacticalMastery,
          type: ObjectiveType.tyreStintLength,
          targetValue: 18,
          rewardMillions: 2,
          confidenceBonus: 6,
          confidencePenalty: 0,
        ),
      );
    } else {
      objectives.add(
        const BoardObjective(
          id: 'obj_sponsor_clean',
          title: 'Title Sponsor Clean Finish Bounty',
          description: 'Bring both cars home across the chequered flag with zero DNFs.',
          category: ObjectiveCategory.sponsorBounty,
          type: ObjectiveType.cleanRaceNoDnf,
          targetValue: 2,
          rewardMillions: 3,
          confidenceBonus: 6,
          confidencePenalty: 4,
        ),
      );
    }

    return objectives;
  }

  static String _findClosestRival(String playerTeamId, List<ChampionshipStanding> standings) {
    if (standings.isEmpty) {
      return playerTeamId == 'red_bull' ? 'ferrari' : 'red_bull';
    }

    int myIdx = standings.indexWhere((s) => s.id == playerTeamId);
    if (myIdx == -1) {
      return standings.first.id != playerTeamId ? standings.first.id : standings.last.id;
    }

    // Pick adjacent team in standings
    if (myIdx > 0) {
      return standings[myIdx - 1].id;
    } else if (myIdx + 1 < standings.length) {
      return standings[myIdx + 1].id;
    }

    return 'ferrari';
  }
}

