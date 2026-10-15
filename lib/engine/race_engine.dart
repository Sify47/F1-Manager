import 'dart:math';
import '../models/driver.dart';
import '../models/team.dart';
import '../models/circuit.dart';
import '../models/tire.dart';
import '../models/race_state.dart';
import '../models/race_event.dart';
import '../models/race_strategy_plan.dart';
import '../data/drivers_data.dart';
import '../data/teams_data.dart';
import 'tire_model.dart';
import 'weather_engine.dart';
import 'incident_engine.dart';
import 'strategy_generator.dart';
import '../services/audio_service.dart';

class RaceEngine {
  final Circuit circuit;
  final WeatherEngine weatherEngine;
  final IncidentEngine incidentEngine;

  List<CarTelemetry> _cars;
  int _currentLap = 1;
  SafetyCarStatus _safetyCarStatus = SafetyCarStatus.clear;
  int _safetyCarLapsRemaining = 0;
  final List<RaceEvent> _eventsHistory = [];
  final List<RadioMessage> _radioHistory = [];
  final List<BattleActionCard> _recentBattles = [];
  double _elapsedRaceSeconds = 0.0;
  bool _isRaceFinished = false;

  Map<String, DriverRaceStrategy> _carStrategies = {};
  final Map<String, int> _lastAlertLapByDriver = {};
  final Set<String> _manualPaceOverrideDrivers = {};

  RaceEngine({
    required this.circuit,
    required List<String> startingGridDriverIds,
    Map<String, TireType>? startingTires,
    Map<String, DriverRaceStrategy>? startingStrategies,
    int? seed,
  })  : weatherEngine = WeatherEngine(
          baseRainProbability: circuit.baseRainProbability,
          baseTrackTemp: circuit.baseTrackTemperature,
          seed: seed,
        ),
        incidentEngine = IncidentEngine(seed: seed),
        _cars = [] {
    _carStrategies = StrategyGenerator.assignGridStrategies(
      circuit: circuit,
      startingGridDriverIds: startingGridDriverIds,
      playerStrategies: startingStrategies,
    );
    _initializeGrid(startingGridDriverIds, startingTires);
  }

  List<CarTelemetry> get cars => List.unmodifiable(_cars);
  int get currentLap => _currentLap;
  SafetyCarStatus get safetyCarStatus => _safetyCarStatus;
  List<RaceEvent> get eventsHistory => List.unmodifiable(_eventsHistory);
  List<RadioMessage> get radioHistory => List.unmodifiable(_radioHistory);
  List<BattleActionCard> get recentBattles => List.unmodifiable(_recentBattles);
  double get elapsedRaceSeconds => _elapsedRaceSeconds;
  bool get isRaceFinished => _isRaceFinished;
  Map<String, DriverRaceStrategy> get carStrategies => Map.unmodifiable(_carStrategies);

  DriverRaceStrategy? getStrategyForDriver(String driverId) => _carStrategies[driverId];

  void updateDriverStrategy(String driverId, DriverRaceStrategy strategy) {
    _carStrategies[driverId] = strategy;
  }

  void toggleAutoExecutePitStops(String driverId, bool auto) {
    if (_carStrategies.containsKey(driverId)) {
      _carStrategies[driverId] = _carStrategies[driverId]!.copyWith(autoExecutePitStops: auto);
    }
  }

  void _initializeGrid(List<String> startingGridDriverIds, Map<String, TireType>? startingTires) {
    _cars = [];
    for (int i = 0; i < startingGridDriverIds.length; i++) {
      String driverId = startingGridDriverIds[i];
      Driver? driver = DriversData.getDriverById(driverId);
      if (driver == null) continue;
      Team? team = TeamsData.getTeamById(driver.teamId);
      if (team == null) continue;

      TireType tireType = startingTires?[driverId] ??
          (_carStrategies[driverId]?.activeStints.isNotEmpty == true
              ? _carStrategies[driverId]!.activeStints.first.compound
              : (i < 10 ? TireType.soft : TireType.medium));
      TireCompound compound = TireCompound.fromType(tireType);
      PaceMode startPace = _carStrategies[driverId]?.activeStints.first.recommendedPace ?? PaceMode.balanced;

      // Starting fuel: ~105-110 kg
      double startingFuel = 105.0;

      _cars.add(CarTelemetry(
        driverId: driverId,
        teamId: team.id,
        position: i + 1,
        startingPosition: i + 1,
        currentLap: 1,
        currentSector: 1,
        sectorProgress: 0.0,
        trackDistanceTravelledKm: 0.0,
        lastLapTime: 0.0,
        bestLapTime: 0.0,
        currentLapTime: 0.0,
        gapToLeaderSeconds: i * 0.35, // Grid slot spacing
        intervalToAheadSeconds: i == 0 ? 0.0 : 0.35,
        sector1Times: [],
        sector2Times: [],
        sector3Times: [],
        currentTire: compound,
        tireWearPercentage: 0.0,
        tireTemperature: 95.0,
        fuelRemainingKg: startingFuel,
        ersBatteryPercentage: 1.0,
        wingDamagePercentage: 0.0,
        pitStopsCount: 0,
        lapsOnCurrentTire: 0,
        paceMode: startPace,
        fuelMix: FuelMix.standard,
        ersMode: ErsMode.balanced,
        boxThisLap: false,
        status: CarRaceStatus.racing,
        hasDrsAvailable: false,
        driverConfidence: 0.90,
      ));
    }
  }

  /// Advance simulation tick by deltaSeconds (e.g. 0.5s or 1.0s)
  void tick(double deltaSeconds) {
    if (_isRaceFinished) return;

    _elapsedRaceSeconds += deltaSeconds;
    WeatherState weather = weatherEngine.tick(deltaSeconds);

    // Check Safety Car timer
    if (_safetyCarStatus != SafetyCarStatus.clear) {
      if (_safetyCarLapsRemaining <= 0) {
        _endSafetyCar();
      }
    }

    // Process every car on the track
    for (int i = 0; i < _cars.length; i++) {
      if (_cars[i].status == CarRaceStatus.outOfRace) continue;

      _simulateCarSector(i, deltaSeconds, weather);
    }

    // Sort standings by total distance travelled and update positions & gaps
    _updateStandings();

    // Check race finish
    if (_cars.isNotEmpty && _cars.first.currentLap > circuit.totalLaps) {
      _isRaceFinished = true;
      AudioService().playChequeredFlag();
      _eventsHistory.add(RaceEvent(
        id: 'chequered_flag',
        lap: circuit.totalLaps,
        sector: 3,
        title: 'CHEQUERED FLAG! 🏁',
        description: '${DriversData.getDriverById(_cars.first.driverId)?.fullName ?? "The Leader"} wins the ${circuit.grandPrixName}!',
        severity: EventSeverity.good,
        driverId: _cars.first.driverId,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _simulateCarSector(int index, double deltaSeconds, WeatherState weather) {
    CarTelemetry car = _cars[index];
    Driver? driver = DriversData.getDriverById(car.driverId);
    Team? team = TeamsData.getTeamById(car.teamId);
    if (driver == null || team == null) return;

    TrackSector sector = circuit.sectors[car.currentSector - 1];

    // 1. Calculate Base Sector Speed / Pace
    double benchmarkSeconds = sector.baseBenchmarkSeconds;

    // Corner Skill & Car Downforce contribution
    int slowCorners = sector.countCorners(CornerSpeedType.slow);
    int medCorners = sector.countCorners(CornerSpeedType.medium);
    int fastCorners = sector.countCorners(CornerSpeedType.fast);
    int straights = sector.countCorners(CornerSpeedType.straight);

    // Car factor
    double carPaceBoost = 0.0;
    carPaceBoost += (team.car.lowSpeedDownforce - 85) * 0.03 * slowCorners;
    carPaceBoost += (team.car.mediumSpeedDownforce - 85) * 0.03 * medCorners;
    carPaceBoost += (team.car.highSpeedDownforce - 85) * 0.04 * fastCorners;
    carPaceBoost += (team.car.topSpeed - 85) * 0.035 * straights;

    // Driver skill factor
    double driverPaceBoost = 0.0;
    driverPaceBoost += (driver.stats.corneringSlow - 85) * 0.025 * slowCorners;
    driverPaceBoost += (driver.stats.corneringMedium - 85) * 0.025 * medCorners;
    driverPaceBoost += (driver.stats.corneringFast - 85) * 0.035 * fastCorners;
    driverPaceBoost += (driver.stats.braking - 85) * 0.03 * (slowCorners + medCorners);

    // Wet skill modifier
    if (weather.trackWetness > 0.20) {
      driverPaceBoost += (driver.stats.wetWeatherSkill - 85) * 0.06 * weather.trackWetness;
    }

    // Tire delta (wear & compound)
    double tireDelta = TireModel.calculatePaceDelta(
      compound: car.currentTire,
      currentWearPercentage: car.tireWearPercentage,
      trackTemp: weather.trackTemperature,
      rainIntensity: weather.rainIntensity,
    ) * (sector.lengthKm / circuit.lengthKm);

    // Fuel weight effect: 0.3s per 10kg over baseline (start is ~105kg, end is ~5kg)
    double fuelPenalty = (car.fuelRemainingKg / 10.0) * 0.3 * (sector.lengthKm / circuit.lengthKm);

    // Pace mode delta
    double paceDelta = 0.0;
    switch (car.paceMode) {
      case PaceMode.conserve:
        paceDelta = 0.8 * (sector.lengthKm / circuit.lengthKm);
        break;
      case PaceMode.balanced:
        paceDelta = 0.0;
        break;
      case PaceMode.push:
        paceDelta = -0.6 * (sector.lengthKm / circuit.lengthKm);
        break;
      case PaceMode.attack:
        paceDelta = -1.1 * (sector.lengthKm / circuit.lengthKm);
        break;
    }

    // ERS mode delta
    double ersDelta = 0.0;
    if (car.ersBatteryPercentage > 0.05) {
      switch (car.ersMode) {
        case ErsMode.charge:
          ersDelta = 0.7 * (sector.lengthKm / circuit.lengthKm);
          break;
        case ErsMode.balanced:
          ersDelta = 0.0;
          break;
        case ErsMode.deploy:
          ersDelta = -0.6 * (sector.lengthKm / circuit.lengthKm);
          break;
        case ErsMode.overtake:
          ersDelta = -1.2 * (sector.lengthKm / circuit.lengthKm);
          break;
      }
    }

    // DRS Boost if available
    double drsDelta = car.hasDrsAvailable ? -0.45 * (sector.lengthKm / circuit.lengthKm) : 0.0;

    // Wing damage penalty
    double wingPenalty = car.wingDamagePercentage * 2.5 * (sector.lengthKm / circuit.lengthKm);

    // Safety Car speed cap
    double targetSectorTime = benchmarkSeconds - (carPaceBoost + driverPaceBoost) / 3.0 +
        tireDelta + fuelPenalty + paceDelta + ersDelta + drsDelta + wingPenalty;

    if (_safetyCarStatus == SafetyCarStatus.virtualSafetyCar) {
      targetSectorTime *= 1.35; // 35% delta delta lap time
    } else if (_safetyCarStatus == SafetyCarStatus.fullSafetyCar) {
      targetSectorTime *= 1.65; // SC bunching pace
    }

    // Calculate progression speed in sector
    double sectorProgressIncrement = deltaSeconds / max(targetSectorTime, 5.0);
    double newSectorProgress = car.sectorProgress + sectorProgressIncrement;

    // Tire Wear update for this tick
    double wearDelta = TireModel.calculateSectorWear(
      compound: car.currentTire,
      asphaltAbrasiveness: circuit.asphaltAbrasiveness,
      driverTyreManagement: driver.stats.tyreManagement,
      carTyrePreservation: team.car.tyrePreservation,
      paceMode: car.paceMode,
      rainIntensity: weather.rainIntensity,
      sectorLengthKm: sector.lengthKm * sectorProgressIncrement,
    );
    double newTireWear = (car.tireWearPercentage + wearDelta).clamp(0.0, 1.0);

    // Fuel Consumption (burn rate: ~1.8kg to 2.3kg per lap)
    double baseFuelBurn = (1.9 / circuit.totalLaps) * sectorProgressIncrement;
    if (car.fuelMix == FuelMix.rich || car.paceMode == PaceMode.attack) baseFuelBurn *= 1.35;
    if (car.fuelMix == FuelMix.lean || car.paceMode == PaceMode.conserve) baseFuelBurn *= 0.75;
    double newFuel = max(0.5, car.fuelRemainingKg - baseFuelBurn);

    // ERS battery drain / recharge
    double battery = car.ersBatteryPercentage;
    if (car.ersMode == ErsMode.charge) {
      battery = min(1.0, battery + 0.02 * deltaSeconds);
    } else if (car.ersMode == ErsMode.deploy) {
      battery = max(0.0, battery - 0.015 * deltaSeconds);
    } else if (car.ersMode == ErsMode.overtake) {
      battery = max(0.0, battery - 0.035 * deltaSeconds);
    }

    // Check for incident / mistake
    if (_safetyCarStatus == SafetyCarStatus.clear) {
      RaceEvent? incident = incidentEngine.evaluateDriverMistake(
        driver: driver,
        team: team,
        telemetry: car,
        trackWetness: weather.trackWetness,
        currentLap: car.currentLap,
        sector: car.currentSector,
      );

      if (incident != null) {
        _eventsHistory.add(incident);
        if (incident.severity == EventSeverity.critical) {
          // Car retired (DNF) and triggers Safety Car!
          _cars[index] = car.copyWith(
            status: CarRaceStatus.outOfRace,
            dnfReason: incident.title,
          );
          _deploySafetyCar(SafetyCarStatus.fullSafetyCar, 3);
          return;
        } else {
          // Lost time due to lockup or off-track
          newSectorProgress = max(0.0, newSectorProgress - 0.12);
        }
      }
    }

    // Evaluate Autonomous AI Pit & Strategy decisions
    _evaluateCarStrategyDecision(index, weather);
    car = _cars[index];

    // Check if sector completed
    int currentSector = car.currentSector;
    int currentLap = car.currentLap;
    double currentLapTime = car.currentLapTime + deltaSeconds;
    double lastLapTime = car.lastLapTime;
    double bestLapTime = car.bestLapTime;
    int lapsOnTire = car.lapsOnCurrentTire;

    if (newSectorProgress >= 1.0) {
      newSectorProgress = 0.0;
      if (currentSector == 1) {
        currentSector = 2;
      } else if (currentSector == 2) {
        currentSector = 3;
      } else {
        // Lap Completed!
        currentSector = 1;
        currentLap++;
        lapsOnTire++;
        lastLapTime = currentLapTime;
        if (bestLapTime == 0.0 || currentLapTime < bestLapTime) {
          bestLapTime = currentLapTime;
        }
        currentLapTime = 0.0;

        // Pit Stop Check
        if (car.boxThisLap) {
          _executePitStop(index, team, driver);
          return;
        }
      }
    }

    _cars[index] = car.copyWith(
      currentLap: currentLap,
      currentSector: currentSector,
      sectorProgress: newSectorProgress,
      trackDistanceTravelledKm: car.trackDistanceTravelledKm + (sector.lengthKm * sectorProgressIncrement),
      currentLapTime: currentLapTime,
      lastLapTime: lastLapTime,
      bestLapTime: bestLapTime,
      tireWearPercentage: newTireWear,
      fuelRemainingKg: newFuel,
      ersBatteryPercentage: battery,
      lapsOnCurrentTire: lapsOnTire,
    );
  }

  void _executePitStop(int index, Team team, Driver driver) {
    CarTelemetry car = _cars[index];
    PitStopResult pitResult = incidentEngine.calculatePitStopDuration(
      team: team,
      repairWing: car.repairWingInPit,
    );

    TireType targetType = car.nextPitTire ?? TireType.hard;
    TireCompound newTire = TireCompound.fromType(targetType);

    // Advance stint in DriverRaceStrategy
    DriverRaceStrategy? strat = _carStrategies[driver.id];
    PaceMode newPace = car.paceMode;
    if (strat != null) {
      DriverRaceStrategy advanced = strat.advanceStint();
      _carStrategies[driver.id] = advanced;
      if (advanced.currentStint != null) {
        newPace = advanced.currentStint!.recommendedPace;
      }
    }

    // Realistic Pit Loss calculation:
    // Full green flag pit loss vs reduced delta under Safety Car
    double pitLossSeconds = pitResult.durationSeconds +
        (_safetyCarStatus != SafetyCarStatus.clear
            ? circuit.pitLaneLossSeconds * 0.52
            : circuit.pitLaneLossSeconds);

    // Speed benchmark on circuit (m/s)
    double avgSpeedMps = (circuit.lengthKm * 1000.0) / circuit.baseLapRecordSeconds;
    // Real distance deficit incurred by spending ~20-25s in the pit lane
    double distanceDeficitKm = (avgSpeedMps * pitLossSeconds) / 1000.0;

    int oldPosition = car.position;
    double newDistance = max(0.0, car.trackDistanceTravelledKm - distanceDeficitKm);

    // Add event log
    AudioService().playPitGun();
    String eventDesc = '${driver.lastName} pitted for ${newTire.name} (Stop: ${pitResult.durationSeconds.toStringAsFixed(1)}s, Pit Loss: ${pitLossSeconds.toStringAsFixed(1)}s)';
    if (pitResult.hasError && pitResult.errorNote != null) {
      eventDesc += ' - ${pitResult.errorNote}';
    }

    _eventsHistory.add(RaceEvent(
      id: 'pit_${DateTime.now().millisecondsSinceEpoch}_${driver.id}',
      lap: car.currentLap,
      sector: 1,
      title: pitResult.hasError ? 'SLOW PIT STOP!' : 'BOX COMPLETE',
      description: eventDesc,
      severity: pitResult.hasError ? EventSeverity.warning : EventSeverity.info,
      driverId: driver.id,
      timestamp: DateTime.now(),
    ));

    _cars[index] = car.copyWith(
      currentTire: newTire,
      tireWearPercentage: 0.0,
      lapsOnCurrentTire: 0,
      boxThisLap: false,
      wingDamagePercentage: car.repairWingInPit ? 0.0 : car.wingDamagePercentage,
      repairWingInPit: false,
      pitStopsCount: car.pitStopsCount + 1,
      paceMode: newPace,
      trackDistanceTravelledKm: newDistance,
      currentLapTime: car.currentLapTime + pitLossSeconds,
    );

    // Immediately re-sort standings to calculate authentic rejoined position and gaps
    _updateStandings();

    int newPosition = _cars.firstWhere((c) => c.driverId == driver.id, orElse: () => car).position;
    int placesLost = newPosition - oldPosition;

    String radioText;
    if (placesLost > 0) {
      radioText = 'Good stop (${pitResult.durationSeconds.toStringAsFixed(1)}s). We rejoin P$newPosition (dropped $placesLost ${placesLost == 1 ? "position" : "positions"}). Time to push!';
    } else {
      radioText = 'Mega in-lap and stop (${pitResult.durationSeconds.toStringAsFixed(1)}s)! We retained P$newPosition!';
    }

    _addRadioMessage(
      RadioMessage(
        id: 'rad_exit_${DateTime.now().millisecondsSinceEpoch}_${driver.id}',
        driverId: driver.id,
        driverShortName: driver.shortCode,
        sender: RadioSender.raceEngineer,
        text: radioText,
        lap: car.currentLap,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _addRadioMessage(RadioMessage msg) {
    _radioHistory.insert(0, msg);
    AudioService().playRadioBeep();
  }

  void _evaluateCarStrategyDecision(int index, WeatherState weather) {
    CarTelemetry car = _cars[index];
    if (car.boxThisLap || car.status == CarRaceStatus.outOfRace) return;
    DriverRaceStrategy? strat = _carStrategies[car.driverId];
    if (strat == null) return;
    Driver? driver = DriversData.getDriverById(car.driverId);
    if (driver == null) return;

    bool isAiOrAuto = strat.autoExecutePitStops;
    int lastAlertLap = _lastAlertLapByDriver[car.driverId] ?? -1;

    // 1. Wet Weather Transition
    if (weather.rainIntensity > 0.25 &&
        car.currentTire.type != TireType.intermediate &&
        car.currentTire.type != TireType.wet) {
      TireType wetTire = weather.rainIntensity > 0.65 ? TireType.wet : TireType.intermediate;
      if (isAiOrAuto) {
        _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: wetTire);
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.raceEngineer,
            text: 'Rain intensifying! Boxing this lap for ${wetTire == TireType.wet ? "Wets" : "Intermediates"}.',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
        return;
      } else if (lastAlertLap != car.currentLap) {
        _lastAlertLapByDriver[car.driverId] = car.currentLap;
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.chiefStrategist,
            text: 'STRATEGY ALERT: Track is wet (${(weather.rainIntensity * 100).toInt()}% rain)! Box now for ${wetTire == TireType.wet ? "WET" : "INTERMEDIATE"} tyres!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    // 2. Track Drying Transition (Crossover back to slicks)
    if (weather.rainIntensity == 0.0 &&
        weather.trackWetness < 0.15 &&
        (car.currentTire.type == TireType.intermediate || car.currentTire.type == TireType.wet)) {
      TireType slickTire = circuit.asphaltAbrasiveness > 0.75 ? TireType.hard : TireType.medium;
      if (isAiOrAuto) {
        _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: slickTire);
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.raceEngineer,
            text: 'Track has dried up. Boxing this lap for slicks (${slickTire.name.toUpperCase()}).',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
        return;
      } else if (lastAlertLap != car.currentLap) {
        _lastAlertLapByDriver[car.driverId] = car.currentLap;
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.chiefStrategist,
            text: 'DRY LINE FORMING: Crossover point reached. Box this lap for slicks!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    // 3. Critical Tyre Cliff (> 72% wear)
    if (car.tireWearPercentage >= 0.72 && car.currentLap < circuit.totalLaps) {
      TireType nextCompound = strat.nextStint?.compound ?? (circuit.totalLaps - car.currentLap > 12 ? TireType.hard : TireType.soft);
      if (isAiOrAuto) {
        _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: nextCompound);
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.raceEngineer,
            text: 'Tyres have fallen off the cliff (${(car.tireWearPercentage * 100).toInt()}% wear)! Boxing now!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
        return;
      } else if (lastAlertLap != car.currentLap) {
        _lastAlertLapByDriver[car.driverId] = car.currentLap;
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.chiefStrategist,
            text: 'CRITICAL TYRE CLIFF: Degradation at ${(car.tireWearPercentage * 100).toInt()}%. Box this lap to protect pace!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    // 4. Scheduled Stint Pit Stop
    StintPlan? currentStint = strat.currentStint;
    StintPlan? nextStint = strat.nextStint;
    if (currentStint != null && nextStint != null && car.currentLap < circuit.totalLaps) {
      if (car.currentLap >= currentStint.endLap) {
        if (isAiOrAuto) {
          _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: nextStint.compound);
          _addRadioMessage(
            RadioMessage(
              id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
              driverId: car.driverId,
              driverShortName: driver.shortCode,
              sender: RadioSender.raceEngineer,
              text: 'Stint target reached. Boxing this lap for ${nextStint.compound.name.toUpperCase()}.',
              lap: car.currentLap,
              timestamp: DateTime.now(),
            ),
          );
          return;
        } else if (lastAlertLap != car.currentLap) {
          _lastAlertLapByDriver[car.driverId] = car.currentLap;
          _addRadioMessage(
            RadioMessage(
              id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
              driverId: car.driverId,
              driverShortName: driver.shortCode,
              sender: RadioSender.chiefStrategist,
              text: 'PIT WINDOW OPEN: Target Lap ${currentStint.endLap} reached. Box this lap for ${nextStint.compound.name.toUpperCase()}!',
              lap: car.currentLap,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    }

    // 5. Opportunistic Safety Car / VSC Pit Stop
    if (_safetyCarStatus != SafetyCarStatus.clear &&
        car.tireWearPercentage > 0.38 &&
        car.currentLap < circuit.totalLaps - 5) {
      TireType scCompound = strat.nextStint?.compound ?? (circuit.totalLaps - car.currentLap > 15 ? TireType.hard : TireType.soft);
      if (isAiOrAuto && car.lapsOnCurrentTire >= 8) {
        _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: scCompound);
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.raceEngineer,
            text: 'Safety Car deployed! Taking cheap pit stop delta!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
        return;
      } else if (!isAiOrAuto && lastAlertLap != car.currentLap) {
        _lastAlertLapByDriver[car.driverId] = car.currentLap;
        _addRadioMessage(
          RadioMessage(
            id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.chiefStrategist,
            text: 'CHEAP PIT WINDOW: Safety Car deployed. Box now to gain 10+ seconds over green flag stops!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    // 6. Tactical Undercut Attack (AI Smart Pit Window Trigger)
    if (isAiOrAuto && currentStint != null && nextStint != null && car.currentLap < circuit.totalLaps) {
      if (car.currentLap >= currentStint.endLap - 2 &&
          car.intervalToAheadSeconds < 1.8 &&
          car.intervalToAheadSeconds > 0.0 &&
          car.tireWearPercentage >= 0.45) {
        _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: nextStint.compound);
        _eventsHistory.add(RaceEvent(
          id: 'undercut_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
          lap: car.currentLap,
          sector: car.currentSector,
          title: '⚡ TACTICAL UNDERCUT!',
          description: '${driver.lastName} dives into the pits early to attempt an undercut on the car ahead!',
          severity: EventSeverity.warning,
          driverId: car.driverId,
          timestamp: DateTime.now(),
        ));
        _addRadioMessage(
          RadioMessage(
            id: 'rad_undercut_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
            driverId: car.driverId,
            driverShortName: driver.shortCode,
            sender: RadioSender.chiefStrategist,
            text: 'UNDERCUT TRIGGERED: Box now to clear dirty air and jump the car ahead on fresh tyres!',
            lap: car.currentLap,
            timestamp: DateTime.now(),
          ),
        );
        return;
      }
    }

    // 7. Dynamic AI Pace & ERS Management
    if (isAiOrAuto && !_manualPaceOverrideDrivers.contains(car.driverId)) {
      if (car.hasDrsAvailable && car.ersBatteryPercentage > 0.20) {
        if (car.paceMode != PaceMode.attack) {
          _cars[index] = car.copyWith(paceMode: PaceMode.attack, ersMode: ErsMode.overtake);
        }
      } else if (car.tireWearPercentage > 0.58 && car.paceMode == PaceMode.attack) {
        _cars[index] = car.copyWith(paceMode: PaceMode.balanced, ersMode: ErsMode.balanced);
      }
    }
  }

  void _deploySafetyCar(SafetyCarStatus status, int laps) {
    _safetyCarStatus = status;
    _safetyCarLapsRemaining = laps;
    _eventsHistory.add(RaceEvent(
      id: 'sc_${DateTime.now().millisecondsSinceEpoch}',
      lap: _currentLap,
      sector: 1,
      title: status == SafetyCarStatus.virtualSafetyCar ? 'VIRTUAL SAFETY CAR' : 'SAFETY CAR DEPLOYED! 🏎️',
      description: status == SafetyCarStatus.virtualSafetyCar
          ? 'Reduce speed and maintain delta. Pit lane is open!'
          : 'Safety Car deployed. Pack bunching up. Opportunity for a cheap pit stop!',
      severity: EventSeverity.warning,
      timestamp: DateTime.now(),
    ));
  }

  void _endSafetyCar() {
    _safetyCarStatus = SafetyCarStatus.clear;
    _eventsHistory.add(RaceEvent(
      id: 'green_${DateTime.now().millisecondsSinceEpoch}',
      lap: _currentLap,
      sector: 1,
      title: 'GREEN FLAG! 🟢',
      description: 'Safety Car in this lap. Racing resumes!',
      severity: EventSeverity.good,
      timestamp: DateTime.now(),
    ));
  }

  void _updateStandings() {
    // Sort cars by total distance travelled descending
    _cars.sort((a, b) {
      if (a.status == CarRaceStatus.outOfRace && b.status != CarRaceStatus.outOfRace) return 1;
      if (b.status == CarRaceStatus.outOfRace && a.status != CarRaceStatus.outOfRace) return -1;
      return b.trackDistanceTravelledKm.compareTo(a.trackDistanceTravelledKm);
    });

    if (_cars.isEmpty) return;
    _currentLap = _cars.first.currentLap;

    // Update positions and calculate gap to leader & intervals
    double leaderDist = _cars.first.trackDistanceTravelledKm;

    for (int i = 0; i < _cars.length; i++) {
      if (_cars[i].status == CarRaceStatus.outOfRace) {
        _cars[i] = _cars[i].copyWith(position: i + 1);
        continue;
      }

      double distDiffToLeader = leaderDist - _cars[i].trackDistanceTravelledKm;
      // Convert km to approximate seconds based on average track speed (~210 km/h = ~58 m/s)
      double gapToLeader = (distDiffToLeader * 1000.0) / 58.0;

      double intervalToAhead = 0.0;
      if (i > 0 && _cars[i - 1].status != CarRaceStatus.outOfRace) {
        double distDiffToAhead = _cars[i - 1].trackDistanceTravelledKm - _cars[i].trackDistanceTravelledKm;
        intervalToAhead = (distDiffToAhead * 1000.0) / 58.0;
      }

      // DRS detection: within 1.0 second of car ahead and in DRS zone
      bool drs = intervalToAhead < 1.0 && intervalToAhead > 0.0;

      // Check if position changed (Overtake!)
      if (_cars[i].position != i + 1 && _cars[i].position > i + 1) {
        // Car moved UP the order (completed an overtake)
        Driver? attDriver = DriversData.getDriverById(_cars[i].driverId);
        Driver? defDriver = (i + 1 < _cars.length) ? DriversData.getDriverById(_cars[i + 1].driverId) : null;
        if (attDriver != null && defDriver != null) {
          _recentBattles.insert(
            0,
            BattleActionCard(
              id: 'btl_${DateTime.now().millisecondsSinceEpoch}',
              lap: _currentLap,
              attackerDriverId: attDriver.id,
              defenderDriverId: defDriver.id,
              headline: '🔥 OVERTAKE FOR P${i + 1}!',
              detail: '${attDriver.lastName} pulled off a brilliant move on ${defDriver.lastName} into Sector ${_cars[i].currentSector}!',
              isSuccessfulOvertake: true,
            ),
          );
          if (_recentBattles.length > 5) _recentBattles.removeLast();
        }
      }

      _cars[i] = _cars[i].copyWith(
        position: i + 1,
        gapToLeaderSeconds: gapToLeader,
        intervalToAheadSeconds: intervalToAhead,
        hasDrsAvailable: drs,
      );
    }
  }

  /// Player commands
  void setDriverPaceMode(String driverId, PaceMode mode) {
    _manualPaceOverrideDrivers.add(driverId);
    int idx = _cars.indexWhere((c) => c.driverId == driverId);
    if (idx != -1) {
      _cars[idx] = _cars[idx].copyWith(paceMode: mode);
    }
  }

  void setDriverFuelMix(String driverId, FuelMix mix) {
    int idx = _cars.indexWhere((c) => c.driverId == driverId);
    if (idx != -1) {
      _cars[idx] = _cars[idx].copyWith(fuelMix: mix);
    }
  }

  void setDriverErsMode(String driverId, ErsMode mode) {
    _manualPaceOverrideDrivers.add(driverId);
    int idx = _cars.indexWhere((c) => c.driverId == driverId);
    if (idx != -1) {
      _cars[idx] = _cars[idx].copyWith(ersMode: mode);
    }
  }

  void orderPitStop(String driverId, TireType nextTire, {bool repairWing = false}) {
    int idx = _cars.indexWhere((c) => c.driverId == driverId);
    if (idx != -1) {
      _cars[idx] = _cars[idx].copyWith(
        boxThisLap: true,
        nextPitTire: nextTire,
        repairWingInPit: repairWing,
      );
      AudioService().playBoxConfirm();
      Driver? d = DriversData.getDriverById(driverId);
      _addRadioMessage(
        RadioMessage(
          id: 'rad_${DateTime.now().millisecondsSinceEpoch}',
          driverId: driverId,
          driverShortName: d?.shortCode ?? 'DRV',
          sender: RadioSender.teamPrincipal,
          text: 'Box box, box this lap. Fitting ${TireCompound.fromType(nextTire).shortCode}.',
          lap: _currentLap,
          timestamp: DateTime.now(),
        ),
      );
    }
  }
}
