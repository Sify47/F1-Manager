import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/circuit.dart';
import '../models/driver.dart';
import '../models/team.dart';
import '../models/tire.dart';
import '../models/race_state.dart';
import '../models/race_event.dart';
import '../data/drivers_data.dart';
import '../engine/race_engine.dart';
import '../engine/pit_wall_strategy.dart';

import '../models/race_strategy_plan.dart';

class RaceController extends ChangeNotifier {
  final Circuit circuit;
  final Team playerTeam;
  late final RaceEngine _engine;
  Timer? _simTimer;

  int _simSpeed = 1; // 0 = paused, 1 = 1x, 2 = 2x, 5 = 5x, 10 = 10x
  bool _disposed = false;

  RaceController({
    required this.circuit,
    required this.playerTeam,
    List<String>? startingGridDriverIds,
    Map<String, TireType>? startingTires,
    Map<String, DriverRaceStrategy>? startingStrategies,
  }) {
    // Generate initial grid from qualifying or standard grid
    final grid = startingGridDriverIds ?? DriversData.allDrivers.map((d) => d.id).toList();
    _engine = RaceEngine(
      circuit: circuit,
      startingGridDriverIds: grid,
      startingTires: startingTires,
      startingStrategies: startingStrategies,
    );
    _startTimer();
  }

  RaceEngine get engine => _engine;
  int get simSpeed => _simSpeed;
  int get currentLap => _engine.currentLap;
  List<CarTelemetry> get cars => _engine.cars;
  SafetyCarStatus get safetyCarStatus => _engine.safetyCarStatus;
  List<RaceEvent> get eventsHistory => _engine.eventsHistory;
  List<RadioMessage> get radioHistory => _engine.radioHistory;
  List<BattleActionCard> get recentBattles => _engine.recentBattles;
  bool get isRaceFinished => _engine.isRaceFinished;

  // Player's 2 drivers
  Driver? get playerDriver1 => DriversData.getDriverById(playerTeam.driverIds[0]);
  Driver? get playerDriver2 => DriversData.getDriverById(playerTeam.driverIds[1]);

  CarTelemetry? get playerCar1 {
    try {
      return _engine.cars.firstWhere((c) => c.driverId == playerTeam.driverIds[0]);
    } catch (_) {
      return null;
    }
  }

  CarTelemetry? get playerCar2 {
    try {
      return _engine.cars.firstWhere((c) => c.driverId == playerTeam.driverIds[1]);
    } catch (_) {
      return null;
    }
  }

  void setSimSpeed(int speed) {
    _simSpeed = speed;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _simTimer?.cancel();
    if (_simSpeed == 0 || _disposed) return;

    // Base tick interval: 200ms
    // If simSpeed is 1x -> advances 0.2s of race
    // If simSpeed is 5x -> advances 1.0s of race
    // If simSpeed is 10x -> advances 2.0s of race
    int intervalMs = 200;
    double deltaSeconds = (intervalMs / 1000.0) * _simSpeed;

    _simTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_disposed || _engine.isRaceFinished) {
        timer.cancel();
        return;
      }
      _engine.tick(deltaSeconds);
      notifyListeners();
    });
  }

  // Strategy commands for player
  void setDriverPace(String driverId, PaceMode mode) {
    _engine.setDriverPaceMode(driverId, mode);
    notifyListeners();
  }

  void setDriverFuel(String driverId, FuelMix mix) {
    _engine.setDriverFuelMix(driverId, mix);
    notifyListeners();
  }

  void setDriverErs(String driverId, ErsMode mode) {
    _engine.setDriverErsMode(driverId, mode);
    notifyListeners();
  }

  void orderPitStop(String driverId, TireType nextTire, {bool repairWing = false}) {
    _engine.orderPitStop(driverId, nextTire, repairWing: repairWing);
    notifyListeners();
  }

  DriverRaceStrategy? getDriverStrategy(String driverId) {
    return _engine.getStrategyForDriver(driverId);
  }

  void updateDriverStrategy(String driverId, DriverRaceStrategy strategy) {
    _engine.updateDriverStrategy(driverId, strategy);
    notifyListeners();
  }

  void toggleAutoStrategy(String driverId, bool auto) {
    _engine.toggleAutoExecutePitStops(driverId, auto);
    notifyListeners();
  }

  UndercutPrediction? getUndercutPrediction(String driverId) {
    try {
      CarTelemetry car = _engine.cars.firstWhere((c) => c.driverId == driverId);
      return PitWallStrategy.calculateUndercut(
        pittingCar: car,
        allCars: _engine.cars,
        circuit: circuit,
        estimatedPitStopDuration: 2.5,
        safetyCarStatus: _engine.safetyCarStatus,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _simTimer?.cancel();
    super.dispose();
  }
}
