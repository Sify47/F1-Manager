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
import '../models/interactive_decision.dart';

class RaceEngine {
  final Circuit circuit;
  final WeatherEngine weatherEngine;
  final IncidentEngine incidentEngine;
  final String? playerTeamId;

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
  final Set<String> _manualPaceOverrideDrivers = {};
  final Set<String> _triggeredDecisionKeys = {};
  InteractiveDecision? _currentDecision;

  RaceEngine({
    required this.circuit,
    required List<String> startingGridDriverIds,
    this.playerTeamId,
    Map<String, TireType>? startingTires,
    Map<String, DriverRaceStrategy>? startingStrategies,
    Map<String, int>? driverMoraleMap,
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
    _initializeGrid(startingGridDriverIds, startingTires, driverMoraleMap);
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
  InteractiveDecision? get currentDecision => _currentDecision;
  bool get hasPendingDecision => _currentDecision != null;

  DriverRaceStrategy? getStrategyForDriver(String driverId) => _carStrategies[driverId];

  void updateDriverStrategy(String driverId, DriverRaceStrategy strategy) {
    _carStrategies[driverId] = strategy;
  }

  void toggleAutoExecutePitStops(String driverId, bool auto) {
    if (_carStrategies.containsKey(driverId)) {
      _carStrategies[driverId] = _carStrategies[driverId]!.copyWith(autoExecutePitStops: auto);
    }
  }

  void _initializeGrid(
    List<String> startingGridDriverIds,
    Map<String, TireType>? startingTires, [
    Map<String, int>? driverMoraleMap,
  ]) {
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

      double confidence = 0.90;
      if (driverMoraleMap != null && driverMoraleMap.containsKey(driverId)) {
        final morale = driverMoraleMap[driverId] ?? 75;
        confidence = (0.50 + (morale / 100.0) * 0.48).clamp(0.40, 0.98);
      }

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
        driverConfidence: confidence,
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

    // Driver Morale & Confidence modifier (0.90 baseline: higher confidence yields pace, lower loses pace)
    driverPaceBoost += (car.driverConfidence - 0.90) * 0.35 * (sector.lengthKm / circuit.lengthKm);

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

    // Aerodynamic Dirty Air & Slipstream
    bool isInDirtyAir = car.intervalToAheadSeconds > 0.0 && car.intervalToAheadSeconds < 1.6;
    double dirtyAirDelta = 0.0;
    if (isInDirtyAir) {
      if (car.hasDrsAvailable) {
        // High-speed slipstream draft on straights/DRS zones
        dirtyAirDelta = -0.28 * (sector.lengthKm / circuit.lengthKm);
      } else {
        // Turbulent wake understeer in technical corners
        dirtyAirDelta = 0.35 * (sector.lengthKm / circuit.lengthKm);
      }
    }

    // Dynamic Tire Thermal Window (Core & Surface Temperature in Celsius)
    double tempDelta = 0.0;
    switch (car.paceMode) {
      case PaceMode.conserve:
        tempDelta -= 0.35 * deltaSeconds;
        break;
      case PaceMode.balanced:
        tempDelta += (98.0 - car.tireTemperature) * 0.03 * deltaSeconds;
        break;
      case PaceMode.push:
        tempDelta += 0.28 * deltaSeconds;
        break;
      case PaceMode.attack:
        tempDelta += 0.58 * deltaSeconds;
        break;
    }
    if (isInDirtyAir) tempDelta += 0.22 * deltaSeconds;
    if (weather.trackTemperature > 36.0) tempDelta += 0.12 * deltaSeconds;
    if (weather.rainIntensity > 0.15) tempDelta -= 0.65 * deltaSeconds;
    double newTireTemp = (car.tireTemperature + tempDelta).clamp(65.0, 135.0);

    // Thermal Grip Delta: Blistering (>115°C) and Cold Graining (<80°C)
    double thermalDelta = 0.0;
    if (newTireTemp > 115.0) {
      thermalDelta = 0.75 * (sector.lengthKm / circuit.lengthKm);
    } else if (newTireTemp < 80.0) {
      thermalDelta = 0.60 * (sector.lengthKm / circuit.lengthKm);
    }

    // Wing damage penalty
    double wingPenalty = car.wingDamagePercentage * 2.5 * (sector.lengthKm / circuit.lengthKm);

    // Safety Car speed cap
    double targetSectorTime = benchmarkSeconds - (carPaceBoost + driverPaceBoost) / 3.0 +
        tireDelta + fuelPenalty + paceDelta + ersDelta + drsDelta + wingPenalty +
        dirtyAirDelta + thermalDelta;

    if (_safetyCarStatus == SafetyCarStatus.virtualSafetyCar) {
      targetSectorTime *= 1.35; // 35% delta delta lap time
    } else if (_safetyCarStatus == SafetyCarStatus.fullSafetyCar) {
      targetSectorTime *= 1.65; // SC bunching pace
    }

    // Calculate progression speed in sector
    double sectorProgressIncrement = deltaSeconds / max(targetSectorTime, 5.0);
    double newSectorProgress = car.sectorProgress + sectorProgressIncrement;

    // Tire Wear update for this tick (boosted by dirty air turbulence and overheating)
    double wearMultiplier = 1.0;
    if (isInDirtyAir) wearMultiplier *= 1.35;
    if (newTireTemp > 115.0) wearMultiplier *= 1.45;

    double wearDelta = TireModel.calculateSectorWear(
      compound: car.currentTire,
      asphaltAbrasiveness: circuit.asphaltAbrasiveness,
      driverTyreManagement: driver.stats.tyreManagement,
      carTyrePreservation: team.car.tyrePreservation,
      paceMode: car.paceMode,
      rainIntensity: weather.rainIntensity,
      sectorLengthKm: sector.lengthKm * sectorProgressIncrement,
    ) * wearMultiplier;
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
      tireTemperature: newTireTemp,
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

    // A. Player Team Interactive Crisis Management
    if (playerTeamId != null && car.teamId == playerTeamId) {
      if (_currentDecision == null) {
        _checkPlayerInteractiveCrisis(index, car, driver, weather, strat);
      }
      return;
    }

    // B. AI Competitor 3-Tier Decision Scoring Engine
    _evaluateAiCandidateDecisions(index, car, driver, weather, strat);
  }

  void _checkPlayerInteractiveCrisis(
    int index,
    CarTelemetry car,
    Driver driver,
    WeatherState weather,
    DriverRaceStrategy strat,
  ) {
    // 1. Critical Tyre Blistering / Degradation Cliff
    if ((car.tireWearPercentage >= 0.70 || car.tireTemperature > 118.0) && car.currentLap < circuit.totalLaps) {
      String key = 'tyre_${car.driverId}_${car.pitStopsCount}';
      if (!_triggeredDecisionKeys.contains(key)) {
        _triggeredDecisionKeys.add(key);
        TireType bestCompound = strat.nextStint?.compound ??
            (circuit.totalLaps - car.currentLap > 12 ? TireType.hard : TireType.soft);

        _currentDecision = InteractiveDecision(
          id: 'dec_tyre_${DateTime.now().millisecondsSinceEpoch}',
          lap: car.currentLap,
          sector: car.currentSector,
          driverId: car.driverId,
          driverShortName: driver.shortCode,
          headline: 'CRITICAL TYRE CRISIS & BLISTERING!',
          radioSnippet: '"Vibrations are unbearable! The tyres have fallen off the cliff, zero traction!"',
          situationDetail: 'Degradation reached ${(car.tireWearPercentage * 100).toInt()}% with core temp at ${car.tireTemperature.toStringAsFixed(0)}°C. Lap times will bleed +2.5s.',
          type: DecisionType.tyreCrisis,
          timestamp: DateTime.now(),
          options: [
            DecisionOption(
              id: 'box_now',
              title: 'BOX THIS LAP FOR ${bestCompound.name.toUpperCase()}',
              description: 'Pit now to fit fresh rubber.',
              pros: 'Eliminates blowout risk; unlocks peak grip and fastest pace.',
              cons: 'Drops positions based on live track gap (~22s pit lane traversal).',
              actionType: DecisionActionType.boxImmediately,
              targetCompound: bestCompound,
            ),
            DecisionOption(
              id: 'lift_coast',
              title: 'LIFT & COAST TO COOL TYRES',
              description: 'Instruct driver to save rubber and back off.',
              pros: 'Cools core temperature by ~0.4°C/sec to preserve remaining tread.',
              cons: 'Pace drops +0.8s/lap, rivals behind will close into DRS range.',
              actionType: DecisionActionType.liftAndCoast,
            ),
            DecisionOption(
              id: 'push_through',
              title: 'STAY OUT & ATTACK (DEFEND POSITION)',
              description: 'Gamble on staying out to keep track position.',
              pros: 'Holds current track position on circuit.',
              cons: '25% risk of instant puncture blowout or massive flat-spot lockup.',
              actionType: DecisionActionType.stayOutAndPush,
            ),
          ],
        );
        AudioService().playRadioBeep();
        return;
      }
    }

    // 2. Weather Transition Crisis
    if (weather.rainIntensity > 0.25 &&
        car.currentTire.type != TireType.intermediate &&
        car.currentTire.type != TireType.wet) {
      String key = 'rain_${car.driverId}_${car.currentLap}';
      if (!_triggeredDecisionKeys.contains(key)) {
        _triggeredDecisionKeys.add(key);
        TireType wetCompound = weather.rainIntensity > 0.65 ? TireType.wet : TireType.intermediate;

        _currentDecision = InteractiveDecision(
          id: 'dec_rain_${DateTime.now().millisecondsSinceEpoch}',
          lap: car.currentLap,
          sector: car.currentSector,
          driverId: car.driverId,
          driverShortName: driver.shortCode,
          headline: 'RAIN INTENSIFYING ACROSS THE CIRCUIT!',
          radioSnippet: '"Rain is dumping across Sector 2! Standing water on kerbs, slick tyres are ice skates!"',
          situationDetail: 'Track wetness is ${(weather.trackWetness * 100).toInt()}% with rain intensity ${(weather.rainIntensity * 100).toInt()}%. Slicks lose ~6-10s per lap.',
          type: DecisionType.weatherGamble,
          timestamp: DateTime.now(),
          options: [
            DecisionOption(
              id: 'box_inters',
              title: 'BOX NOW FOR ${wetCompound == TireType.wet ? "FULL WET" : "INTERMEDIATE"} TYRES',
              description: 'Switch immediately to grooved rain rubber.',
              pros: 'Full drainage grip: 6 to 10 seconds faster per lap in the wet.',
              cons: 'If rain clears after 2 laps, tyres will overheat and shred on dry tarmac.',
              actionType: DecisionActionType.boxImmediately,
              targetCompound: wetCompound,
            ),
            DecisionOption(
              id: 'stay_slicks',
              title: 'STAY OUT ON SLICKS (WEATHER GAMBLE)',
              description: 'Brave the rain and hope it clears soon.',
              pros: 'Saves 24s pit stop if radar shows rain will pass quickly.',
              cons: 'Extreme aquaplaning risk, high chance of spin into gravel.',
              actionType: DecisionActionType.stayOutAndPush,
            ),
          ],
        );
        AudioService().playRadioBeep();
        return;
      }
    }

    // 3. Safety Car Cheap Pit Window
    if (_safetyCarStatus != SafetyCarStatus.clear &&
        car.tireWearPercentage > 0.35 &&
        car.lapsOnCurrentTire >= 6 &&
        car.currentLap < circuit.totalLaps - 5) {
      String key = 'sc_${car.driverId}_$_safetyCarLapsRemaining';
      if (!_triggeredDecisionKeys.contains(key)) {
        _triggeredDecisionKeys.add(key);
        TireType scCompound = strat.nextStint?.compound ?? (circuit.totalLaps - car.currentLap > 15 ? TireType.hard : TireType.soft);

        _currentDecision = InteractiveDecision(
          id: 'dec_sc_${DateTime.now().millisecondsSinceEpoch}',
          lap: car.currentLap,
          sector: car.currentSector,
          driverId: car.driverId,
          driverShortName: driver.shortCode,
          headline: 'SAFETY CAR DEPLOYED: CHEAP PIT WINDOW!',
          radioSnippet: '"Safety Car is out! Pack is bunching up. Pit loss delta is cut in half!"',
          situationDetail: 'Under Safety Car, you save ~11 seconds compared to green-flag pit stops.',
          type: DecisionType.safetyCarWindow,
          timestamp: DateTime.now(),
          options: [
            DecisionOption(
              id: 'sc_box',
              title: 'BOX NOW FOR CHEAP STOP (${scCompound.name.toUpperCase()})',
              description: 'Take the discounted pit stop under the safety car.',
              pros: 'Save 11+ seconds; restart with fresh tires right behind the pack.',
              cons: 'Concedes track position to cars that choose to stay out.',
              actionType: DecisionActionType.boxImmediately,
              targetCompound: scCompound,
            ),
            DecisionOption(
              id: 'sc_stay',
              title: 'STAY OUT & MAINTAIN TRACK POSITION',
              description: 'Keep track position at the front of the queue.',
              pros: 'Inherit track position and control the restart pace.',
              cons: 'Will have to pit later under green-flag conditions at full time penalty.',
              actionType: DecisionActionType.stayOutAndPush,
            ),
          ],
        );
        AudioService().playRadioBeep();
        return;
      }
    }

    // 4. Teammate Conflict (Driver 1 vs Driver 2 close battle)
    final teamCars = _cars.where((c) => c.teamId == playerTeamId).toList();
    if (teamCars.length == 2 && car.driverId == teamCars[1].driverId) {
      teamCars.sort((a, b) => a.position.compareTo(b.position));
      final carAhead = teamCars[0];
      final carBehind = teamCars[1];
      double interval = carBehind.intervalToAheadSeconds;

      if (interval > 0.0 && interval < 1.3 && carBehind.paceMode == PaceMode.attack) {
        String key = 'team_swap_${car.currentLap}';
        if (!_triggeredDecisionKeys.contains(key)) {
          _triggeredDecisionKeys.add(key);
          Driver? dAhead = DriversData.getDriverById(carAhead.driverId);
          Driver? dBehind = DriversData.getDriverById(carBehind.driverId);

          _currentDecision = InteractiveDecision(
            id: 'dec_team_${DateTime.now().millisecondsSinceEpoch}',
            lap: car.currentLap,
            sector: car.currentSector,
            driverId: carBehind.driverId,
            driverShortName: dBehind?.shortCode ?? 'DRV',
            headline: 'TEAMMATE CONFLICT: DRIVER BEHIND IS FASTER!',
            radioSnippet: '"${dBehind?.lastName}: I am much faster than him! He is holding me up in dirty air!"',
            situationDetail: '${dBehind?.lastName} (P${carBehind.position}) is attacking ${dAhead?.lastName} (P${carAhead.position}) within ${interval.toStringAsFixed(1)}s.',
            type: DecisionType.teammateConflict,
            timestamp: DateTime.now(),
            options: [
              DecisionOption(
                id: 'swap_teammates',
                title: 'TEAM ORDER: SWAP POSITIONS',
                description: 'Order car ahead to move aside into turn 1.',
                pros: 'Releases faster car into clean air to hunt rivals ahead.',
                cons: 'May anger ${dAhead?.lastName} (check ego) and lower morale.',
                actionType: DecisionActionType.swapTeammates,
              ),
              DecisionOption(
                id: 'hold_stations',
                title: 'TEAM ORDER: HOLD STATIONS',
                description: 'Freeze positions to protect constructor points.',
                pros: 'Zero risk of teammate collision; guarantees solid finish.',
                cons: 'Car behind remains stuck in dirty air with elevated tire wear.',
                actionType: DecisionActionType.holdPositions,
              ),
            ],
          );
          AudioService().playRadioBeep();
          return;
        }
      }
    }
  }

  void _evaluateAiCandidateDecisions(
    int index,
    CarTelemetry car,
    Driver driver,
    WeatherState weather,
    DriverRaceStrategy strat,
  ) {
    StintPlan? currentStint = strat.currentStint;
    StintPlan? nextStint = strat.nextStint;

    // 1. Wet Transition Check (Score: ~100-130)
    if (weather.rainIntensity > 0.25 &&
        car.currentTire.type != TireType.intermediate &&
        car.currentTire.type != TireType.wet) {
      TireType targetWet = weather.rainIntensity > 0.65 ? TireType.wet : TireType.intermediate;
      _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: targetWet);
      _addRadioMessage(
        RadioMessage(
          id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
          driverId: car.driverId,
          driverShortName: driver.shortCode,
          sender: RadioSender.raceEngineer,
          text: 'Rain intensifying! Boxing this lap for ${targetWet == TireType.wet ? "Wets" : "Inters"}.',
          lap: car.currentLap,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    // 2. Dry line Crossover (Score: ~90)
    if (weather.rainIntensity == 0.0 &&
        weather.trackWetness < 0.15 &&
        (car.currentTire.type == TireType.intermediate || car.currentTire.type == TireType.wet)) {
      TireType slickTire = circuit.asphaltAbrasiveness > 0.75 ? TireType.hard : TireType.medium;
      _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: slickTire);
      _addRadioMessage(
        RadioMessage(
          id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
          driverId: car.driverId,
          driverShortName: driver.shortCode,
          sender: RadioSender.raceEngineer,
          text: 'Drying line formed! Boxing this lap for ${slickTire.name.toUpperCase()}.',
          lap: car.currentLap,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    // 3. Critical Tire Cliff (Score: ~95)
    if (car.tireWearPercentage >= 0.72 && car.currentLap < circuit.totalLaps) {
      TireType nextCompound = nextStint?.compound ?? (circuit.totalLaps - car.currentLap > 12 ? TireType.hard : TireType.soft);
      _cars[index] = car.copyWith(boxThisLap: true, nextPitTire: nextCompound);
      _addRadioMessage(
        RadioMessage(
          id: 'rad_${DateTime.now().millisecondsSinceEpoch}_${car.driverId}',
          driverId: car.driverId,
          driverShortName: driver.shortCode,
          sender: RadioSender.raceEngineer,
          text: 'Tires have hit the cliff (${(car.tireWearPercentage * 100).toInt()}% wear)! Boxing now!',
          lap: car.currentLap,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    // 4. Tactical Undercut candidate scoring
    if (currentStint != null && nextStint != null && car.currentLap < circuit.totalLaps) {
      double undercutScore = 0.0;
      if (car.currentLap >= currentStint.endLap - 3) {
        if (car.intervalToAheadSeconds < 1.8 && car.intervalToAheadSeconds > 0.0) {
          undercutScore += 50.0;
        }
        if (car.tireWearPercentage >= 0.42) {
          undercutScore += 25.0;
        }
        if (driver.personality == DriverPersonality.tacticalMastermind) {
          undercutScore += 30.0;
        } else if (driver.personality == DriverPersonality.aggressiveAttacker) {
          undercutScore += 20.0;
        }
      }

      if (undercutScore >= 70.0) {
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

    // 5. Opportunistic Safety Car Candidate
    if (_safetyCarStatus != SafetyCarStatus.clear &&
        car.lapsOnCurrentTire >= 7 &&
        car.currentLap < circuit.totalLaps - 5) {
      double scScore = 40.0 + (car.tireWearPercentage * 40.0);
      if (driver.personality == DriverPersonality.underdogGambler) {
        scScore += 30.0;
      }
      if (scScore >= 60.0) {
        TireType scCompound = nextStint?.compound ?? (circuit.totalLaps - car.currentLap > 15 ? TireType.hard : TireType.soft);
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
      }
    }

    // 6. Scheduled Stint Pit Stop
    if (currentStint != null && nextStint != null && car.currentLap < circuit.totalLaps) {
      int targetLap = currentStint.endLap;
      if (driver.personality == DriverPersonality.smoothConserver && car.tireWearPercentage < 0.48) {
        targetLap += 2; // Conserver extends stint!
      }
      if (car.currentLap >= targetLap) {
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
      }
    }

    // 7. Dynamic AI Pace & ERS Management (Personality-driven)
    if (!_manualPaceOverrideDrivers.contains(car.driverId)) {
      if (car.hasDrsAvailable && car.ersBatteryPercentage > 0.25 && car.tireTemperature < 112.0) {
        if (driver.personality == DriverPersonality.aggressiveAttacker || car.ersBatteryPercentage > 0.50) {
          if (car.paceMode != PaceMode.attack) {
            _cars[index] = car.copyWith(paceMode: PaceMode.attack, ersMode: ErsMode.overtake);
          }
        }
      } else if (car.tireWearPercentage > 0.58 || car.tireTemperature > 114.0) {
        if (car.paceMode == PaceMode.attack) {
          _cars[index] = car.copyWith(
            paceMode: driver.personality == DriverPersonality.smoothConserver ? PaceMode.conserve : PaceMode.balanced,
            ersMode: ErsMode.balanced,
          );
        }
      }
    }
  }

  void resolveDecision(DecisionOption option) {
    if (_currentDecision == null) return;
    final dec = _currentDecision!;
    _currentDecision = null;

    final carIdx = _cars.indexWhere((c) => c.driverId == dec.driverId);
    if (carIdx == -1) return;
    CarTelemetry car = _cars[carIdx];
    Driver? driver = DriversData.getDriverById(car.driverId);

    switch (option.actionType) {
      case DecisionActionType.boxImmediately:
        orderPitStop(car.driverId, option.targetCompound ?? TireType.hard);
        break;

      case DecisionActionType.liftAndCoast:
        setDriverPaceMode(car.driverId, PaceMode.conserve);
        setDriverFuelMix(car.driverId, FuelMix.lean);
        _addRadioMessage(
          RadioMessage(
            id: 'rad_resp_${DateTime.now().millisecondsSinceEpoch}',
            driverId: car.driverId,
            driverShortName: driver?.shortCode ?? 'DRV',
            sender: RadioSender.driver,
            text: 'Copy, lifting and coasting into turn 1 to manage tyre temperatures.',
            lap: _currentLap,
            timestamp: DateTime.now(),
          ),
        );
        break;

      case DecisionActionType.stayOutAndPush:
        setDriverPaceMode(car.driverId, PaceMode.attack);
        if (Random().nextDouble() < 0.25) {
          _eventsHistory.add(
            RaceEvent(
              id: 'flat_${DateTime.now().millisecondsSinceEpoch}',
              lap: _currentLap,
              sector: car.currentSector,
              title: '⚠️ TYRE FLAT-SPOT & LOCKUP!',
              description: '${driver?.lastName ?? "Driver"} locked up aggressively pushing on worn rubber! Massive vibrations.',
              severity: EventSeverity.warning,
              driverId: car.driverId,
              timestamp: DateTime.now(),
            ),
          );
        }
        _addRadioMessage(
          RadioMessage(
            id: 'rad_push_${DateTime.now().millisecondsSinceEpoch}',
            driverId: car.driverId,
            driverShortName: driver?.shortCode ?? 'DRV',
            sender: RadioSender.driver,
            text: 'Understood, staying out to defend track position. Giving it everything!',
            lap: _currentLap,
            timestamp: DateTime.now(),
          ),
        );
        break;

      case DecisionActionType.swapTeammates:
        executeTeamOrder(TeamOrderType.swapPositions);
        break;

      case DecisionActionType.holdPositions:
        executeTeamOrder(TeamOrderType.holdPositions);
        break;

      case DecisionActionType.attackWithErs:
        setDriverPaceMode(car.driverId, PaceMode.attack);
        setDriverErsMode(car.driverId, ErsMode.overtake);
        break;

      case DecisionActionType.defendAggressive:
        setDriverPaceMode(car.driverId, PaceMode.push);
        setDriverErsMode(car.driverId, ErsMode.deploy);
        break;
    }
  }

  void executeTeamOrder(TeamOrderType order) {
    if (playerTeamId == null) return;
    final teamCars = _cars.where((c) => c.teamId == playerTeamId).toList();
    if (teamCars.length < 2) return;

    teamCars.sort((a, b) => a.position.compareTo(b.position));
    final carAhead = teamCars[0];
    final carBehind = teamCars[1];

    Driver? driverAhead = DriversData.getDriverById(carAhead.driverId);
    Driver? driverBehind = DriversData.getDriverById(carBehind.driverId);

    if (order == TeamOrderType.swapPositions) {
      int ego = driverAhead?.stats.ego ?? 70;
      bool willDefy = ego > 88 && Random().nextDouble() < 0.35;

      if (willDefy) {
        _addRadioMessage(
          RadioMessage(
            id: 'rad_defy_${DateTime.now().millisecondsSinceEpoch}',
            driverId: carAhead.driverId,
            driverShortName: driverAhead?.shortCode ?? 'DRV',
            sender: RadioSender.driver,
            text: 'Negative, negative! I have the pace, tell him to close the gap on merit!',
            lap: _currentLap,
            timestamp: DateTime.now(),
          ),
        );
        _eventsHistory.add(
          RaceEvent(
            id: 'defy_${DateTime.now().millisecondsSinceEpoch}',
            lap: _currentLap,
            sector: carAhead.currentSector,
            title: '📻 TEAM ORDER DEFIED!',
            description: '${driverAhead?.lastName} refused team order to let ${driverBehind?.lastName} through!',
            severity: EventSeverity.warning,
            driverId: carAhead.driverId,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        int idxAhead = _cars.indexWhere((c) => c.driverId == carAhead.driverId);
        int idxBehind = _cars.indexWhere((c) => c.driverId == carBehind.driverId);

        if (idxAhead != -1 && idxBehind != -1) {
          double tempDist = _cars[idxAhead].trackDistanceTravelledKm;
          _cars[idxAhead] = _cars[idxAhead].copyWith(trackDistanceTravelledKm: _cars[idxBehind].trackDistanceTravelledKm);
          _cars[idxBehind] = _cars[idxBehind].copyWith(trackDistanceTravelledKm: tempDist + 0.02);
          _updateStandings();

          _addRadioMessage(
            RadioMessage(
              id: 'rad_swap_${DateTime.now().millisecondsSinceEpoch}',
              driverId: carAhead.driverId,
              driverShortName: driverAhead?.shortCode ?? 'DRV',
              sender: RadioSender.driver,
              text: 'Understood. Letting ${driverBehind?.shortCode ?? "teammate"} by into turn 1.',
              lap: _currentLap,
              timestamp: DateTime.now(),
            ),
          );
          _eventsHistory.add(
            RaceEvent(
              id: 'swap_${DateTime.now().millisecondsSinceEpoch}',
              lap: _currentLap,
              sector: carAhead.currentSector,
              title: '🔀 TEAM ORDER: POSITION SWAP',
              description: '${driverAhead?.lastName} moves aside to allow ${driverBehind?.lastName} through.',
              severity: EventSeverity.good,
              driverId: carBehind.driverId,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    } else if (order == TeamOrderType.holdPositions) {
      setDriverPaceMode(carAhead.driverId, PaceMode.balanced);
      setDriverPaceMode(carBehind.driverId, PaceMode.balanced);
      _addRadioMessage(
        RadioMessage(
          id: 'rad_hold_${DateTime.now().millisecondsSinceEpoch}',
          driverId: carBehind.driverId,
          driverShortName: driverBehind?.shortCode ?? 'DRV',
          sender: RadioSender.driver,
          text: 'Copy that. Holding station, bringing the cars home.',
          lap: _currentLap,
          timestamp: DateTime.now(),
        ),
      );
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
