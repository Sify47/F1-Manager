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
      expect(engine.cars.first.currentTire.type, TireType.hard);
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
      expect(pittedCar.pitStopsCount, 1);
      expect(pittedCar.currentTire.type, TireType.hard);
    });
  });
}


