import 'dart:math';
import '../models/circuit.dart';
import '../models/driver.dart';
import '../models/team.dart';
import '../models/weekend_session.dart';
import '../data/drivers_data.dart';
import '../data/teams_data.dart';

class QualifyingEngine {
  final Circuit circuit;
  final Random _random;

  QualifyingEngine({required this.circuit, int? seed}) : _random = Random(seed);

  /// Simulates a flying lap time for a driver in a specific phase
  double _simulateHotLap({
    required Driver driver,
    required Team team,
    required double setupPaceBonus,
    required double trackEvolutionSeconds,
  }) {
    double baseLap = circuit.baseLapRecordSeconds;

    // Car downforce & power contribution (approx -1.5s delta between top & bottom car)
    double carFactor = (team.car.overallRating - 85) * 0.08;

    // Driver hot lap qualifying skill (braking, cornering, composure)
    double driverFactor = ((driver.stats.braking +
                driver.stats.corneringFast +
                driver.stats.reactions +
                driver.stats.composure) /
            4.0 -
        85) *
        0.06;

    // Variance for driver nailing the apexes or making minor micro-corrections (+/- 0.14s)
    double driverVariance = (_random.nextDouble() * 0.28) - 0.14;

    double lap = baseLap - carFactor - driverFactor - setupPaceBonus - trackEvolutionSeconds + driverVariance;
    return max(60.0, lap);
  }

  /// Runs full Q1, Q2, Q3 knockout simulation
  QualifyingResults runFullQualifying({
    Map<String, double>? driverSetupPaceBonuses,
  }) {
    List<Driver> grid = List.from(DriversData.allDrivers);

    // --- PHASE 1: Q1 (All 20 Drivers) ---
    List<DriverQualiLap> q1Laps = [];
    for (var driver in grid) {
      Team? team = TeamsData.getTeamById(driver.teamId);
      if (team == null) continue;
      double setupBonus = driverSetupPaceBonuses?[driver.id] ?? 0.0;
      double lap = _simulateHotLap(
        driver: driver,
        team: team,
        setupPaceBonus: setupBonus,
        trackEvolutionSeconds: 0.0,
      );
      q1Laps.add(DriverQualiLap(
        driverId: driver.id,
        driverShortName: driver.shortCode,
        teamId: team.id,
        lapTimeSeconds: lap,
        gapToLeader: 0.0,
        finalPosition: 0,
      ));
    }
    q1Laps.sort((a, b) => a.lapTimeSeconds.compareTo(b.lapTimeSeconds));
    double q1LeaderTime = q1Laps.first.lapTimeSeconds;

    // Mark Q1 gaps & eliminations (P16 - P20)
    for (int i = 0; i < q1Laps.length; i++) {
      q1Laps[i] = DriverQualiLap(
        driverId: q1Laps[i].driverId,
        driverShortName: q1Laps[i].driverShortName,
        teamId: q1Laps[i].teamId,
        lapTimeSeconds: q1Laps[i].lapTimeSeconds,
        gapToLeader: q1Laps[i].lapTimeSeconds - q1LeaderTime,
        isEliminated: i >= 15,
        finalPosition: i + 1,
      );
    }

    // --- PHASE 2: Q2 (Top 15 Drivers) ---
    List<Driver> q2Drivers = q1Laps.take(15).map((lap) => DriversData.getDriverById(lap.driverId)!).toList();
    List<DriverQualiLap> q2Laps = [];
    for (var driver in q2Drivers) {
      Team? team = TeamsData.getTeamById(driver.teamId);
      if (team == null) continue;
      double setupBonus = driverSetupPaceBonuses?[driver.id] ?? 0.0;
      double lap = _simulateHotLap(
        driver: driver,
        team: team,
        setupPaceBonus: setupBonus,
        trackEvolutionSeconds: 0.35, // Grip rubbered in
      );
      q2Laps.add(DriverQualiLap(
        driverId: driver.id,
        driverShortName: driver.shortCode,
        teamId: team.id,
        lapTimeSeconds: lap,
        gapToLeader: 0.0,
        finalPosition: 0,
      ));
    }
    q2Laps.sort((a, b) => a.lapTimeSeconds.compareTo(b.lapTimeSeconds));
    double q2LeaderTime = q2Laps.first.lapTimeSeconds;

    for (int i = 0; i < q2Laps.length; i++) {
      q2Laps[i] = DriverQualiLap(
        driverId: q2Laps[i].driverId,
        driverShortName: q2Laps[i].driverShortName,
        teamId: q2Laps[i].teamId,
        lapTimeSeconds: q2Laps[i].lapTimeSeconds,
        gapToLeader: q2Laps[i].lapTimeSeconds - q2LeaderTime,
        isEliminated: i >= 10,
        finalPosition: i + 1,
      );
    }

    // --- PHASE 3: Q3 (Top 10 Shootout for POLE POSITION) ---
    List<Driver> q3Drivers = q2Laps.take(10).map((lap) => DriversData.getDriverById(lap.driverId)!).toList();
    List<DriverQualiLap> q3Laps = [];
    for (var driver in q3Drivers) {
      Team? team = TeamsData.getTeamById(driver.teamId);
      if (team == null) continue;
      double setupBonus = driverSetupPaceBonuses?[driver.id] ?? 0.0;
      double lap = _simulateHotLap(
        driver: driver,
        team: team,
        setupPaceBonus: setupBonus,
        trackEvolutionSeconds: 0.65, // Peak track evolution
      );
      q3Laps.add(DriverQualiLap(
        driverId: driver.id,
        driverShortName: driver.shortCode,
        teamId: team.id,
        lapTimeSeconds: lap,
        gapToLeader: 0.0,
        finalPosition: 0,
      ));
    }
    q3Laps.sort((a, b) => a.lapTimeSeconds.compareTo(b.lapTimeSeconds));
    double q3LeaderTime = q3Laps.first.lapTimeSeconds;

    for (int i = 0; i < q3Laps.length; i++) {
      q3Laps[i] = DriverQualiLap(
        driverId: q3Laps[i].driverId,
        driverShortName: q3Laps[i].driverShortName,
        teamId: q3Laps[i].teamId,
        lapTimeSeconds: q3Laps[i].lapTimeSeconds,
        gapToLeader: q3Laps[i].lapTimeSeconds - q3LeaderTime,
        isEliminated: false,
        finalPosition: i + 1,
      );
    }

    // Assemble final official Starting Grid P1 through P20
    List<String> startingGrid = [];
    // P1 to P10 from Q3
    startingGrid.addAll(q3Laps.map((l) => l.driverId));
    // P11 to P15 from Q2
    startingGrid.addAll(q2Laps.skip(10).map((l) => l.driverId));
    // P16 to P20 from Q1
    startingGrid.addAll(q1Laps.skip(15).map((l) => l.driverId));

    return QualifyingResults(
      q1Laps: q1Laps,
      q2Laps: q2Laps,
      q3Laps: q3Laps,
      startingGridDriverIds: startingGrid,
    );
  }
}

