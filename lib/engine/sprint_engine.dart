import '../models/driver.dart';
import '../models/team.dart';
import '../models/circuit.dart';
import '../data/drivers_data.dart';
import '../data/teams_data.dart';
import 'dart:math';

class SprintFinisher {
  final int position;
  final String driverId;
  final String teamId;
  final double gapToLeaderSeconds;
  final int points;

  const SprintFinisher({
    required this.position,
    required this.driverId,
    required this.teamId,
    required this.gapToLeaderSeconds,
    required this.points,
  });
}

class SprintRaceResult {
  final List<SprintFinisher> finishers;
  final Map<String, int> driverPointsGained;
  final Map<String, int> constructorPointsGained;

  const SprintRaceResult({
    required this.finishers,
    required this.driverPointsGained,
    required this.constructorPointsGained,
  });
}

class SprintEngine {
  final Circuit circuit;
  final Random _random;

  SprintEngine({required this.circuit, int? seed})
      : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// Official F1 Sprint points scoring system (Top 8 finishers)
  static const List<int> sprintPointsSystem = [8, 7, 6, 5, 4, 3, 2, 1];

  /// Runs the 100km Sprint Race based on the sprint grid
  SprintRaceResult runSprintRace({
    required List<String> startingGridDriverIds,
    Map<String, double>? driverPaceBonuses,
  }) {
    List<Map<String, dynamic>> performances = [];

    for (int i = 0; i < startingGridDriverIds.length; i++) {
      String driverId = startingGridDriverIds[i];
      Driver? driver = DriversData.getDriverById(driverId);
      if (driver == null) continue;
      Team? team = TeamsData.getTeamById(driver.teamId);
      if (team == null) continue;

      // Base pace score: Car downforce + power + driver pace & racecraft
      double carRating = (team.car.highSpeedDownforce * 0.4) + (team.car.topSpeed * 0.6);
      double driverRating = (driver.stats.overtaking * 0.5) + (driver.stats.braking * 0.5);
      double bonus = driverPaceBonuses?[driverId] ?? 0.0;

      // Grid penalty/advantage (starting P1 is a massive advantage in a short 100km race)
      double gridPenalty = i * 0.8;
      double variance = (_random.nextDouble() * 2.0 - 1.0) * 1.5;

      double sprintScore = (carRating * 0.6) + (driverRating * 0.4) - gridPenalty + variance - (bonus * 10.0);

      performances.add({
        'driverId': driverId,
        'teamId': team.id,
        'score': sprintScore,
      });
    }

    // Sort by performance descending
    performances.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    List<SprintFinisher> finishers = [];
    Map<String, int> driverPts = {};
    Map<String, int> teamPts = {};

    double cumulativeGap = 0.0;

    for (int pos = 0; pos < performances.length; pos++) {
      final entry = performances[pos];
      final String driverId = entry['driverId'];
      final String teamId = entry['teamId'];

      if (pos > 0) {
        cumulativeGap += 0.8 + (_random.nextDouble() * 1.6);
      }

      int pts = pos < sprintPointsSystem.length ? sprintPointsSystem[pos] : 0;

      finishers.add(SprintFinisher(
        position: pos + 1,
        driverId: driverId,
        teamId: teamId,
        gapToLeaderSeconds: cumulativeGap,
        points: pts,
      ));

      if (pts > 0) {
        driverPts[driverId] = pts;
        teamPts[teamId] = (teamPts[teamId] ?? 0) + pts;
      }
    }

    return SprintRaceResult(
      finishers: finishers,
      driverPointsGained: driverPts,
      constructorPointsGained: teamPts,
    );
  }
}
