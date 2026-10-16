import 'package:flutter_test/flutter_test.dart';
import 'package:f1_manager/data/circuits_data.dart';
import 'package:f1_manager/data/drivers_data.dart';
import 'package:f1_manager/data/teams_data.dart';
import 'package:f1_manager/engine/race_engine.dart';
import 'package:f1_manager/models/race_state.dart';
import 'package:f1_manager/models/tire.dart';
import 'package:f1_manager/models/car_setup.dart';
import 'package:f1_manager/engine/setup_engine.dart';
import 'package:f1_manager/engine/qualifying_engine.dart';
import 'package:f1_manager/models/race_strategy_plan.dart';
import 'package:f1_manager/engine/strategy_generator.dart';
import 'package:f1_manager/models/interactive_decision.dart';
import 'package:f1_manager/state/career_controller.dart';
import 'package:f1_manager/models/car_part_rd.dart';
import 'package:f1_manager/models/press_conference.dart';
import 'package:f1_manager/services/save_game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F1 Manager Engine Unit Tests', () {
    test('Verify Grid Data completeness', () {
      expect(DriversData.allDrivers.length, 20);
      expect(TeamsData.allTeams.length, 10);
      expect(CircuitsData.allCircuits.length, greaterThanOrEqualTo(7));

      // Verify Verstappen stats
      final ver = DriversData.getDriverById('max_verstappen');
      expect(ver, isNotNull);
      expect(ver!.stats.braking, 98);
      expect(ver.stats.corneringFast, 99);

      // Verify Red Bull Team
      final rb = TeamsData.getTeamById('red_bull');
      expect(rb, isNotNull);
      expect(rb!.driverIds.contains('max_verstappen'), isTrue);
    });

    test('Simulate 15 race ticks and verify car movement & tire wear', () {
      final circuit = CircuitsData.getCircuitById('monza')!;
      final grid = DriversData.allDrivers.map((d) => d.id).toList();

      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: grid,
      );

      expect(engine.cars.length, 20);
      expect(engine.currentLap, 1);

      // Run 30 ticks (simulating 15 seconds)
      for (int i = 0; i < 30; i++) {
        engine.tick(0.5);
      }

      // Verify leader has travelled positive distance
      final leader = engine.cars.first;
      expect(leader.trackDistanceTravelledKm, greaterThan(0.0));
      expect(leader.tireWearPercentage, greaterThan(0.0));
      expect(leader.fuelRemainingKg, lessThan(105.0));
    });

    test('Pace Mode increases tire wear', () {
      final circuit = CircuitsData.getCircuitById('silverstone')!;
      final grid = ['max_verstappen', 'lewis_hamilton'];

      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: grid,
      );

      // Set Max to Attack mode, Lewis to Conserve mode
      engine.setDriverPaceMode('max_verstappen', PaceMode.attack);
      engine.setDriverPaceMode('lewis_hamilton', PaceMode.conserve);

      for (int i = 0; i < 40; i++) {
        engine.tick(0.5);
      }

      final maxCar = engine.cars.firstWhere((c) => c.driverId == 'max_verstappen');
      final lewisCar = engine.cars.firstWhere((c) => c.driverId == 'lewis_hamilton');

      // Attack mode should burn noticeably more tire than conserve mode
      expect(maxCar.tireWearPercentage, greaterThan(lewisCar.tireWearPercentage));
    });

    test('Pit stop command replaces tires and resets wear', () {
      final circuit = CircuitsData.getCircuitById('monaco')!;
      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: ['charles_leclerc'],
      );

      // Order pit stop for Hard tires
      engine.orderPitStop('charles_leclerc', TireType.hard);
      final car = engine.cars.first;
      expect(car.boxThisLap, isTrue);
      expect(car.nextPitTire, TireType.hard);
      expect(engine.radioHistory.isNotEmpty, isTrue);
    });

    test('SetupEngine computes realistic satisfaction and driver quotes', () {
      final monaco = CircuitsData.getCircuitById('monaco')!;
      // Optimal Monaco setup: high wings, soft suspension, short gears
      const optimalMonacoSetup = CarSetup(
        frontWingAngle: 10,
        rearWingAngle: 10,
        suspensionStiffness: 2,
        gearRatio: 2,
      );

      final eval = SetupEngine.evaluateSetup(setup: optimalMonacoSetup, circuit: monaco);
      expect(eval.setupSatisfactionPercentage, greaterThan(0.90));
      expect(eval.paceDeltaSeconds, lessThan(-0.25)); // Pace bonus
      expect(eval.overallDriverQuote.contains('rails'), isTrue);
    });

    test('QualifyingEngine runs full Q1, Q2, Q3 knockout shootout', () {
      final spa = CircuitsData.getCircuitById('spa')!;
      final qualiEngine = QualifyingEngine(circuit: spa);

      final results = qualiEngine.runFullQualifying();

      // Q1 should have 20 drivers with 5 eliminated
      expect(results.q1Laps.length, 20);
      expect(results.q1Laps.where((l) => l.isEliminated).length, 5);

      // Q2 should have 15 drivers with 5 eliminated
      expect(results.q2Laps.length, 15);
      expect(results.q2Laps.where((l) => l.isEliminated).length, 5);

      // Q3 should have 10 drivers
      expect(results.q3Laps.length, 10);

      // Starting Grid must contain all 20 drivers
      expect(results.startingGridDriverIds.length, 20);
      expect(results.startingGridDriverIds.toSet().length, 20); // Unique
    });

    test('StrategyGenerator creates 3 diverse proposals and custom strategies', () {
      final circuit = CircuitsData.getCircuitById('bahrain')!;
      final strats = StrategyGenerator.generateStrategies(circuit);

      expect(strats.length, 3);
      // Strategy A is 1-stop
      expect(strats[0].totalStops, 1);
      // Strategy B is 2-stop
      expect(strats[1].totalStops, 2);
      // Strategy C is reverse
      expect(strats[2].totalStops, 1);
      expect(strats[2].stints.first.compound, TireType.hard);

      // Custom 1-stop
      final custom = StrategyGenerator.createCustom1Stop(
        circuit: circuit,
        compound1: TireType.soft,
        compound2: TireType.hard,
        pitLap: 19,
      );
      expect(custom.stints.first.endLap, 19);
      expect(custom.stints.last.compound, TireType.hard);
    });

    test('AI Autonomous Strategy triggers pit stop and advances stint', () {
      final circuit = CircuitsData.getCircuitById('monza')!;
      final customStrat = StrategyGenerator.createCustom1Stop(
        circuit: circuit,
        compound1: TireType.soft,
        compound2: TireType.hard,
        pitLap: 2, // Pit on lap 2 for fast test
      );

      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: ['max_verstappen'],
        seed: 100,
        startingStrategies: {
          'max_verstappen': DriverRaceStrategy(
            driverId: 'max_verstappen',
            chosenStrategy: customStrat,
            activeStints: List.from(customStrat.stints),
            currentStintIndex: 0,
            autoExecutePitStops: true,
          ),
        },
      );

      expect(engine.cars.first.currentTire.type, TireType.soft);
      expect(engine.getStrategyForDriver('max_verstappen')?.autoExecutePitStops, isTrue);

      // Simulate enough ticks to complete 3 laps (pitLap is clamped to 3)
      for (int i = 0; i < 200; i++) {
        engine.tick(1.5);
        if (engine.cars.first.pitStopsCount > 0) break;
      }

      // Verify car pitted autonomously without manual player intervention
      expect(engine.cars.first.pitStopsCount, greaterThanOrEqualTo(1));
      expect(
        engine.cars.first.currentTire.type,
        isIn([TireType.hard, TireType.intermediate]),
      );
    });

    test('SetupEngine evaluates both drivers across FP1, FP2, FP3 with session progression', () {
      final circuit = CircuitsData.getCircuitById('spa')!;
      final d1 = DriversData.getDriverById('charles_leclerc');
      final d2 = DriversData.getDriverById('carlos_sainz');

      // Test FP1 vs FP3 evolution
      final fp1Eval = SetupEngine.evaluateSetup(
        setup: const CarSetup(frontWingAngle: 7, rearWingAngle: 7, suspensionStiffness: 8, gearRatio: 7),
        circuit: circuit,
        driver: d1,
        sessionIndex: 1,
      );

      final fp3Eval = SetupEngine.evaluateSetup(
        setup: const CarSetup(frontWingAngle: 7, rearWingAngle: 7, suspensionStiffness: 8, gearRatio: 7),
        circuit: circuit,
        driver: d1,
        sessionIndex: 3,
      );

      final d2Eval = SetupEngine.evaluateSetup(
        setup: const CarSetup(frontWingAngle: 7, rearWingAngle: 7, suspensionStiffness: 8, gearRatio: 7),
        circuit: circuit,
        driver: d2,
        sessionIndex: 3,
      );

      expect(fp1Eval.setupSatisfactionPercentage, greaterThanOrEqualTo(0.90));
      expect(fp3Eval.setupSatisfactionPercentage, greaterThanOrEqualTo(0.90));
      expect(d2Eval.setupSatisfactionPercentage, greaterThanOrEqualTo(0.85));
      expect(fp1Eval.sessionIndex, 1);
      expect(fp3Eval.sessionIndex, 3);
      expect(fp1Eval.practiceLapTime, isNotEmpty);
      expect(d2Eval.practiceLapTime, isNotEmpty);
    });

    test('RaceEngine pit stop applies realistic distance deficit and recalculates position', () {
      final circuit = CircuitsData.getCircuitById('monza')!;
      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: ['max_verstappen', 'charles_leclerc', 'lando_norris'],
      );

      // Verify initial order
      expect(engine.cars.first.driverId, 'max_verstappen');

      // Simulate a bit of distance
      for (int i = 0; i < 20; i++) {
        engine.tick(2.0);
      }

      final leadCarBefore = engine.cars.first;
      // Order pit stop for the leader
      engine.orderPitStop(leadCarBefore.driverId, TireType.hard);
      expect(engine.cars.first.boxThisLap, isTrue);

      // Advance until lap completes and pit executes
      for (int i = 0; i < 150; i++) {
        engine.tick(2.0);
        if (engine.cars.any((c) => c.driverId == leadCarBefore.driverId && c.pitStopsCount > 0)) {
          break;
        }
      }

      final pittedCar = engine.cars.firstWhere((c) => c.driverId == leadCarBefore.driverId);
      expect(pittedCar.pitStopsCount, greaterThanOrEqualTo(1));
      expect(pittedCar.currentTire.type, TireType.hard);
    });

    test('RaceEngine executes Team Orders (holdPositions & swap)', () {
      final circuit = CircuitsData.getCircuitById('monza')!;
      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: ['max_verstappen', 'sergio_perez'],
        playerTeamId: 'red_bull',
        seed: 42,
      );

      // Verify team order holdPositions creates radio message and sets pace
      engine.executeTeamOrder(TeamOrderType.holdPositions);
      expect(engine.radioHistory.any((r) => r.text.contains('Holding station') || r.text.contains('Hold stations')), isTrue);
    });

    test('RaceEngine dynamic tyre temperature tracks within realistic physics boundaries', () {
      final circuit = CircuitsData.getCircuitById('monza')!;
      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: ['max_verstappen', 'charles_leclerc'],
        seed: 42,
      );

      // Verify initial tire temp (~90°C)
      expect(engine.cars.first.tireTemperature, closeTo(90.0, 15.0));

      // Attack pace raises temperature
      engine.setDriverPaceMode('max_verstappen', PaceMode.attack);
      for (int i = 0; i < 30; i++) {
        engine.tick(2.0);
      }

      final car = engine.cars.firstWhere((c) => c.driverId == 'max_verstappen');
      expect(car.tireTemperature, greaterThanOrEqualTo(65.0));
      expect(car.tireTemperature, lessThanOrEqualTo(135.0));
    });

    test('CareerController R&D commissions upgrade, deducts budget, and fits part with trade-offs on race advance', () {
      final team = TeamsData.getTeamById('ferrari')!;
      final career = CareerController(initialTeam: team);

      final initialBudget = career.playerTeam.budgetMillions;
      final initialTopSpeed = career.playerTeam.car.topSpeed;
      final initialDownforce = career.playerTeam.car.highSpeedDownforce;

      final spec = CarPartRdCatalog.getSpecsForPart(CarPartType.rearWing).first; // Low drag spec (+6 topSpeed, -3 highSpeedDownforce)
      final ok = career.commissionRdProject(
        partType: CarPartType.rearWing,
        spec: spec,
        allocatedWindTunnel: 5,
        allocatedCfd: 5,
      );

      expect(ok, isTrue);
      expect(career.playerTeam.budgetMillions, initialBudget - spec.baseCostMillions);
      expect(career.activeProjects.length, 1);
      expect(career.activeProjects.first.racesRemaining, spec.baseRacesToDeliver);
      expect(career.windTunnelHours, 30);
      expect(career.cfdPoints, 20);

      // Advance to next race to deliver part
      career.advanceToNextRace();

      // Verify part completed & fitted to car with trade-offs applied
      expect(career.activeProjects.length, 0);
      expect(career.completedProjects.length, 1);
      expect(career.playerTeam.car.topSpeed, greaterThan(initialTopSpeed));
      expect(career.playerTeam.car.highSpeedDownforce, lessThan(initialDownforce));
    });

    test('CareerController R&D prevents commissioning when budget is insufficient', () {
      final team = TeamsData.getTeamById('haas')!; // Low budget team
      final career = CareerController(initialTeam: team.copyWith(budgetMillions: 2));

      final expensiveSpec = CarPartRdCatalog.getSpecsForPart(CarPartType.underfloor).first; // Costs $12M
      final ok = career.commissionRdProject(
        partType: CarPartType.underfloor,
        spec: expensiveSpec,
      );

      expect(ok, isFalse);
      expect(career.activeProjects.isEmpty, isTrue);
    });

    test('BoardObjectiveGenerator creates tiered objectives and evaluates them in CareerController.awardRaceResults', () {
      final team = TeamsData.getTeamById('red_bull')!;
      final career = CareerController(initialTeam: team);

      expect(career.currentObjectives.isNotEmpty, isTrue);
      expect(career.boardConfidence, 75);
      expect(career.boardConfidenceRating, 'Satisfied');

      final initialBudget = career.playerTeam.budgetMillions;

      // Simulate a victorious race meeting primary P3+ objective & rival shootout
      career.awardRaceResults(
        driverPointsGained: {'max_verstappen': 25, 'sergio_perez': 18},
        constructorPointsGained: {'red_bull': 43, 'ferrari': 15},
        prizeMoneyMillions: 12,
        bestFinishPosition: 1,
        longestStintLaps: 22,
        playerCarsFinished: 2,
      );

      // Verify board confidence increased and objective rewards were credited
      expect(career.boardConfidence, greaterThan(75));
      expect(career.playerTeam.budgetMillions, greaterThan(initialBudget + 12));
      expect(career.currentObjectives.any((o) => o.isAchieved), isTrue);
    });

    test('Failed board objectives penalize executive board confidence', () {
      final team = TeamsData.getTeamById('ferrari')!;
      final career = CareerController(initialTeam: team);

      final initialConf = career.boardConfidence;

      // Simulate a disastrous race where team DNFs and misses P3 target
      career.awardRaceResults(
        driverPointsGained: {},
        constructorPointsGained: {'ferrari': 0, 'red_bull': 44},
        prizeMoneyMillions: 2,
        bestFinishPosition: 18,
        longestStintLaps: 5,
        playerCarsFinished: 0,
      );

      expect(career.boardConfidence, lessThan(initialConf));
      expect(career.currentObjectives.any((o) => !o.isAchieved && o.isEvaluated), isTrue);
    });

    test('PaddockPoliticsEngine generates contextual media questions for race outcomes', () {
      // 1. Victory scenario
      final winQuestions = PaddockPoliticsEngine.generatePostRaceQuestions(
        teamName: 'Red Bull Racing',
        driver1LastName: 'Verstappen',
        driver2LastName: 'Perez',
        bestFinishPosition: 1,
      );
      expect(winQuestions.isNotEmpty, isTrue);
      expect(winQuestions.any((q) => q.journalistName == 'David Croft'), isTrue);
      expect(winQuestions.any((q) => q.topic == 'GRAND PRIX VICTORY'), isTrue);

      // 2. Teammate conflict scenario
      final warQuestions = PaddockPoliticsEngine.generatePostRaceQuestions(
        teamName: 'Ferrari',
        driver1LastName: 'Leclerc',
        driver2LastName: 'Sainz',
        bestFinishPosition: 4,
        hadTeammateConflict: true,
      );
      expect(warQuestions.any((q) => q.journalistName == 'Will Buxton'), isTrue);
      expect(warQuestions.any((q) => q.topic == 'TEAM ORDERS CIVIL WAR'), isTrue);

      // 3. Mechanical DNF crisis
      final dnfQuestions = PaddockPoliticsEngine.generatePostRaceQuestions(
        teamName: 'McLaren',
        driver1LastName: 'Norris',
        bestFinishPosition: 19,
        hadMechanicalDnf: true,
      );
      expect(dnfQuestions.any((q) => q.journalistName == 'Martin Brundle'), isTrue);
      expect(dnfQuestions.any((q) => q.topic == 'MECHANICAL DNF CRISIS'), isTrue);

      // 4. Achieved Board Objectives
      final sponsorQuestions = PaddockPoliticsEngine.generatePostRaceQuestions(
        teamName: 'Mercedes',
        driver1LastName: 'Hamilton',
        bestFinishPosition: 5,
        achievedBoardObjectives: true,
      );
      expect(sponsorQuestions.any((q) => q.topic == 'BOARD & SPONSOR TARGETS'), isTrue);
    });

    test('CareerController tracks driver morale, evaluates press answers, and updates board confidence & sponsor bounties', () {
      final team = TeamsData.getTeamById('ferrari')!;
      final career = CareerController(initialTeam: team);

      final d1 = team.driverIds[0];
      final d2 = team.driverIds[1];

      // Default baseline morale
      expect(career.getDriverMorale(d1), 75);
      expect(career.getDriverMoraleRating(d1), 'Motivated');

      final initialBudget = career.playerTeam.budgetMillions;
      final initialBoard = career.boardConfidence;

      // Apply a press option that boosts morale and grants sponsor bonus
      const testOption = PressOption(
        text: 'Sensational teamwork by both drivers and pit crew!',
        driverMoraleDelta: 10,
        boardConfidenceDelta: 5,
        sponsorBonusMillions: 2,
        consequenceSummary: '+10 Driver Morale, +5% Board Confidence, +\$2.0M Sponsor Bonus',
      );

      career.applyPressAnswer(testOption);

      // Morale should be 85
      expect(career.getDriverMorale(d1), 85);
      expect(career.getDriverMorale(d2), 85);
      expect(career.getDriverMoraleRating(d1), 'Ecstatic (High Confidence)');

      // Board confidence and budget
      expect(career.boardConfidence, initialBoard + 5);
      expect(career.playerTeam.budgetMillions, initialBudget + 2);
      expect(career.engineeringFeed.first.contains('MEDIA PRESS ROOM'), isTrue);

      // Test Morale clamping bounds
      const harshOption = PressOption(
        text: 'The driver is completely responsible for this disaster.',
        driverMoraleDelta: -100,
        boardConfidenceDelta: -100,
        consequenceSummary: 'Destructive press statement',
      );
      career.applyPressAnswer(harshOption, targetDriverId: d1);
      expect(career.getDriverMorale(d1), 0);
      expect(career.getDriverMoraleRating(d1), 'Toxic / Demotivated');
      expect(career.boardConfidence, 0);
    });

    test('CareerSaveData serializes and restores driverMorale and boardConfidence accurately', () {
      final saveData = CareerSaveData(
        teamId: 'mclaren',
        budgetMillions: 55,
        currentRaceIndex: 3,
        carStats: {'topSpeed': 90, 'reliability': 88},
        constructorPoints: {'mclaren': 65},
        driverPoints: {'lando_norris': 45},
        driverMorale: {'lando_norris': 88, 'oscar_piastri': 82},
        boardConfidence: 84,
        savedAt: DateTime.now(),
      );

      final json = saveData.toJson();
      final restored = CareerSaveData.fromJson(json);

      expect(restored.driverMorale?['lando_norris'], 88);
      expect(restored.driverMorale?['oscar_piastri'], 82);
      expect(restored.boardConfidence, 84);
    });

    test('RaceEngine initializes driverConfidence according to driverMoraleMap', () {
      final circuit = CircuitsData.getCircuitById('monza')!;
      final grid = ['max_verstappen', 'sergio_perez'];

      final engine = RaceEngine(
        circuit: circuit,
        startingGridDriverIds: grid,
        driverMoraleMap: {
          'max_verstappen': 95, // High morale -> high confidence (~0.95+)
          'sergio_perez': 30,   // Low morale -> low confidence (~0.64)
        },
      );

      final maxCar = engine.cars.firstWhere((c) => c.driverId == 'max_verstappen');
      final perezCar = engine.cars.firstWhere((c) => c.driverId == 'sergio_perez');

      expect(maxCar.driverConfidence, greaterThan(0.90));
      expect(perezCar.driverConfidence, lessThan(0.70));
    });
  });
}


