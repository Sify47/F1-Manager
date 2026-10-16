import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/circuit.dart';
import '../models/car_part_rd.dart';
import '../models/board_objective.dart';
import '../models/press_conference.dart';
import '../data/teams_data.dart';
import '../data/drivers_data.dart';
import '../data/circuits_data.dart';
import '../services/save_game_service.dart';

class ChampionshipStanding {
  final String id;
  final String name;
  final String shortCode;
  final int points;
  final int wins;
  final int podiums;

  const ChampionshipStanding({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.points,
    required this.wins,
    required this.podiums,
  });

  ChampionshipStanding copyWith({
    int? points,
    int? wins,
    int? podiums,
  }) {
    return ChampionshipStanding(
      id: id,
      name: name,
      shortCode: shortCode,
      points: points ?? this.points,
      wins: wins ?? this.wins,
      podiums: podiums ?? this.podiums,
    );
  }
}

class CareerController extends ChangeNotifier {
  Team _playerTeam;
  int _currentRaceIndex = 0;
  final List<Circuit> _calendar;
  final Map<String, ChampionshipStanding> _driverStandings = {};
  final Map<String, ChampionshipStanding> _constructorStandings = {};
  final Map<String, int> _driverMorale = {};

  final List<RdProject> _rdProjects = [];
  int _windTunnelHours = 35;
  int _cfdPoints = 25;
  final List<String> _engineeringFeed = [
    '🏭 Welcome to the Engineering Headquarters. Ready to develop aerodynamic and powertrain upgrades.'
  ];

  int _boardConfidence = 75;
  List<BoardObjective> _currentObjectives = [];

  CareerController({Team? initialTeam, CareerSaveData? savedData})
      : _playerTeam = initialTeam ?? TeamsData.allTeams.first,
        _calendar = CircuitsData.allCircuits {
    if (savedData != null) {
      _restoreFromSave(savedData);
    } else {
      _initializeStandings();
    }
    _generateWeekendObjectives();
  }

  void _restoreFromSave(CareerSaveData data) {
    Team? baseTeam = TeamsData.getTeamById(data.teamId);
    if (baseTeam != null) {
      _playerTeam = baseTeam.copyWith(
        budgetMillions: data.budgetMillions,
        car: baseTeam.car.copyWith(
          topSpeed: data.carStats['topSpeed'] ?? baseTeam.car.topSpeed,
          acceleration: data.carStats['acceleration'] ?? baseTeam.car.acceleration,
          highSpeedDownforce: data.carStats['highSpeedDownforce'] ?? baseTeam.car.highSpeedDownforce,
          mediumSpeedDownforce: data.carStats['mediumSpeedDownforce'] ?? baseTeam.car.mediumSpeedDownforce,
          lowSpeedDownforce: data.carStats['lowSpeedDownforce'] ?? baseTeam.car.lowSpeedDownforce,
          tyrePreservation: data.carStats['tyrePreservation'] ?? baseTeam.car.tyrePreservation,
          drsEfficiency: data.carStats['drsEfficiency'] ?? baseTeam.car.drsEfficiency,
          reliability: data.carStats['reliability'] ?? baseTeam.car.reliability,
        ),
      );
    }
    _currentRaceIndex = data.currentRaceIndex;

    _initializeStandings();
    for (var entry in data.constructorPoints.entries) {
      if (_constructorStandings.containsKey(entry.key)) {
        _constructorStandings[entry.key] = _constructorStandings[entry.key]!.copyWith(points: entry.value);
      }
    }
    for (var entry in data.driverPoints.entries) {
      if (_driverStandings.containsKey(entry.key)) {
        _driverStandings[entry.key] = _driverStandings[entry.key]!.copyWith(points: entry.value);
      }
    }
    if (data.driverMorale != null) {
      _driverMorale.addAll(data.driverMorale!);
    }
    if (data.boardConfidence != null) {
      _boardConfidence = data.boardConfidence!;
    }
  }

  Team get playerTeam => _playerTeam;
  int get currentRaceIndex => _currentRaceIndex;
  List<Circuit> get calendar => _calendar;
  Circuit get currentCircuit => _calendar[_currentRaceIndex % _calendar.length];

  List<ChampionshipStanding> get sortedDriverStandings {
    var list = _driverStandings.values.toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  List<ChampionshipStanding> get sortedConstructorStandings {
    var list = _constructorStandings.values.toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  void selectTeam(Team team) {
    _playerTeam = team;
    notifyListeners();
    _autoSave();
  }

  void _initializeStandings() {
    for (var team in TeamsData.allTeams) {
      _constructorStandings[team.id] = ChampionshipStanding(
        id: team.id,
        name: team.name,
        shortCode: team.shortName,
        points: 0,
        wins: 0,
        podiums: 0,
      );
    }
    for (var driver in DriversData.allDrivers) {
      _driverStandings[driver.id] = ChampionshipStanding(
        id: driver.id,
        name: driver.fullName,
        shortCode: driver.shortCode,
        points: 0,
        wins: 0,
        podiums: 0,
      );
      _driverMorale[driver.id] = 75;
    }
  }

  // Driver Morale Getters
  Map<String, int> get driverMorale => Map.unmodifiable(_driverMorale);

  int getDriverMorale(String driverId) => _driverMorale[driverId] ?? 75;

  String getDriverMoraleRating(String driverId) {
    final m = getDriverMorale(driverId);
    if (m >= 85) return 'Ecstatic (High Confidence)';
    if (m >= 70) return 'Motivated';
    if (m >= 50) return 'Content';
    if (m >= 35) return 'Frustrated';
    return 'Toxic / Demotivated';
  }

  void applyPressAnswer(PressOption option, {String? targetDriverId}) {
    if (option.driverMoraleDelta != 0) {
      if (option.targetDriverId != null) {
        _modifyDriverMorale(option.targetDriverId!, option.driverMoraleDelta);
      } else if (targetDriverId != null) {
        _modifyDriverMorale(targetDriverId, option.driverMoraleDelta);
      } else {
        for (final dId in _playerTeam.driverIds) {
          _modifyDriverMorale(dId, option.driverMoraleDelta);
        }
      }
    }

    if (option.boardConfidenceDelta != 0) {
      _boardConfidence = (_boardConfidence + option.boardConfidenceDelta).clamp(0, 100);
    }

    if (option.sponsorBonusMillions != 0) {
      _playerTeam = _playerTeam.copyWith(
        budgetMillions: max(0, _playerTeam.budgetMillions + option.sponsorBonusMillions),
      );
    }

    _engineeringFeed.insert(
      0,
      '🎙️ MEDIA PRESS ROOM: "${option.consequenceSummary}"',
    );

    notifyListeners();
    _autoSave();
  }

  void _modifyDriverMorale(String driverId, int delta) {
    final current = getDriverMorale(driverId);
    _driverMorale[driverId] = (current + delta).clamp(0, 100);
  }

  // R&D Getters
  List<RdProject> get rdProjects => List.unmodifiable(_rdProjects);
  List<RdProject> get activeProjects => _rdProjects.where((p) => !p.isCompleted).toList();
  List<RdProject> get completedProjects => _rdProjects.where((p) => p.isCompleted).toList();
  int get windTunnelHours => _windTunnelHours;
  int get cfdPoints => _cfdPoints;
  List<String> get engineeringFeed => List.unmodifiable(_engineeringFeed);

  // Board Objectives & Confidence Getters
  int get boardConfidence => _boardConfidence;
  List<BoardObjective> get currentObjectives => List.unmodifiable(_currentObjectives);
  String get boardConfidenceRating {
    if (_boardConfidence >= 85) return 'Delighted';
    if (_boardConfidence >= 70) return 'Satisfied';
    if (_boardConfidence >= 50) return 'Under Pressure';
    return 'Hot Seat';
  }

  void _generateWeekendObjectives() {
    _currentObjectives = BoardObjectiveGenerator.generateWeekendObjectives(
      team: _playerTeam,
      circuit: currentCircuit,
      raceIndex: _currentRaceIndex,
      constructorStandings: sortedConstructorStandings,
    );
  }

  bool commissionRdProject({
    required CarPartType partType,
    required RdSpecPhilosophy spec,
    bool isRush = false,
    int allocatedWindTunnel = 0,
    int allocatedCfd = 0,
  }) {
    int totalCost = isRush ? (spec.baseCostMillions * 1.4).round() : spec.baseCostMillions;
    if (_playerTeam.budgetMillions < totalCost) return false;
    if (allocatedWindTunnel > _windTunnelHours || allocatedCfd > _cfdPoints) return false;

    // Deduct budget & testing hours
    _playerTeam = _playerTeam.copyWith(
      budgetMillions: _playerTeam.budgetMillions - totalCost,
    );
    _windTunnelHours -= allocatedWindTunnel;
    _cfdPoints -= allocatedCfd;

    int racesToDeliver = spec.baseRacesToDeliver;
    if (isRush && racesToDeliver > 1) {
      racesToDeliver -= 1;
    }

    final newProject = RdProject(
      id: 'rd_${DateTime.now().millisecondsSinceEpoch}_${partType.name}',
      partType: partType,
      specPhilosophy: spec,
      racesRemaining: racesToDeliver,
      isRushDevelopment: isRush,
      startedAt: DateTime.now(),
    );

    _rdProjects.insert(0, newProject);
    _engineeringFeed.insert(
      0,
      '⚙️ Commissioned ${spec.name} (${partType.displayName}) • ETA: $racesToDeliver ${racesToDeliver == 1 ? "Race" : "Races"}${isRush ? " [RUSH ORDER]" : ""}',
    );

    notifyListeners();
    _autoSave();
    return true;
  }

  void _applyCompletedPartToCar(RdProject project) {
    var car = _playerTeam.car;
    final deltas = project.specPhilosophy.statDeltas;
    final defect = project.hadManufacturingDefect;
    double multiplier = defect ? 0.5 : 1.0;

    int newTop = (car.topSpeed + ((deltas['topSpeed'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newAcc = (car.acceleration + ((deltas['acceleration'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newHigh = (car.highSpeedDownforce + ((deltas['highSpeedDownforce'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newMed = (car.mediumSpeedDownforce + ((deltas['mediumSpeedDownforce'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newLow = (car.lowSpeedDownforce + ((deltas['lowSpeedDownforce'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newTyre = (car.tyrePreservation + ((deltas['tyrePreservation'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newDrs = (car.drsEfficiency + ((deltas['drsEfficiency'] ?? 0) * multiplier).round()).clamp(40, 100);
    int newRel = (car.reliability + ((deltas['reliability'] ?? 0) * multiplier).round()).clamp(40, 100);

    _playerTeam = _playerTeam.copyWith(
      car: car.copyWith(
        topSpeed: newTop,
        acceleration: newAcc,
        highSpeedDownforce: newHigh,
        mediumSpeedDownforce: newMed,
        lowSpeedDownforce: newLow,
        tyrePreservation: newTyre,
        drsEfficiency: newDrs,
        reliability: newRel,
      ),
    );

    if (project.partType == CarPartType.pitEquipment) {
      int nextGym = (_playerTeam.facilities.pitCrewGymLevel + 1).clamp(1, 5);
      _playerTeam = _playerTeam.copyWith(
        facilities: TeamFacilities(
          windTunnelLevel: _playerTeam.facilities.windTunnelLevel,
          cfdSupercomputer: _playerTeam.facilities.cfdSupercomputer,
          simulatorLevel: _playerTeam.facilities.simulatorLevel,
          designOfficeLevel: _playerTeam.facilities.designOfficeLevel,
          pitCrewGymLevel: nextGym,
        ),
      );
    }
  }

  // Legacy simple upgrade methods
  bool upgradeCarAero({int costMillions = 8}) {
    if (_playerTeam.budgetMillions < costMillions) return false;
    _playerTeam = _playerTeam.copyWith(
      budgetMillions: _playerTeam.budgetMillions - costMillions,
      car: _playerTeam.car.copyWith(
        highSpeedDownforce: (_playerTeam.car.highSpeedDownforce + 2).clamp(0, 100),
        mediumSpeedDownforce: (_playerTeam.car.mediumSpeedDownforce + 1).clamp(0, 100),
      ),
    );
    notifyListeners();
    _autoSave();
    return true;
  }

  bool upgradeCarEngine({int costMillions = 10}) {
    if (_playerTeam.budgetMillions < costMillions) return false;
    _playerTeam = _playerTeam.copyWith(
      budgetMillions: _playerTeam.budgetMillions - costMillions,
      car: _playerTeam.car.copyWith(
        topSpeed: (_playerTeam.car.topSpeed + 2).clamp(0, 100),
        acceleration: (_playerTeam.car.acceleration + 1).clamp(0, 100),
      ),
    );
    notifyListeners();
    _autoSave();
    return true;
  }

  bool upgradePitCrewGym({int costMillions = 5}) {
    if (_playerTeam.budgetMillions < costMillions) return false;
    if (_playerTeam.facilities.pitCrewGymLevel >= 5) return false;
    _playerTeam = _playerTeam.copyWith(
      budgetMillions: _playerTeam.budgetMillions - costMillions,
      facilities: TeamFacilities(
        windTunnelLevel: _playerTeam.facilities.windTunnelLevel,
        cfdSupercomputer: _playerTeam.facilities.cfdSupercomputer,
        simulatorLevel: _playerTeam.facilities.simulatorLevel,
        designOfficeLevel: _playerTeam.facilities.designOfficeLevel,
        pitCrewGymLevel: _playerTeam.facilities.pitCrewGymLevel + 1,
      ),
    );
    notifyListeners();
    _autoSave();
    return true;
  }

  void advanceToNextRace() {
    _currentRaceIndex = (_currentRaceIndex + 1) % _calendar.length;
    // Award season sponsorship payouts
    _playerTeam = _playerTeam.copyWith(
      budgetMillions: _playerTeam.budgetMillions + 4,
    );

    // Advance R&D active projects
    for (int i = 0; i < _rdProjects.length; i++) {
      if (!_rdProjects[i].isCompleted) {
        int rem = _rdProjects[i].racesRemaining - 1;
        if (rem <= 0) {
          bool hadDefect = false;
          if (_rdProjects[i].isRushDevelopment) {
            hadDefect = Random().nextDouble() < 0.25;
          }
          _rdProjects[i] = _rdProjects[i].copyWith(
            racesRemaining: 0,
            isCompleted: true,
            hadManufacturingDefect: hadDefect,
          );
          _applyCompletedPartToCar(_rdProjects[i]);
          if (hadDefect) {
            _engineeringFeed.insert(
              0,
              '⚠️ DEFECT: Rush delivery on ${_rdProjects[i].specPhilosophy.name} produced minor flaws. Yield halved!',
            );
          } else {
            _engineeringFeed.insert(
              0,
              '✅ UPGRADE FITTED: ${_rdProjects[i].specPhilosophy.name} is now installed on the car!',
            );
          }
        } else {
          _rdProjects[i] = _rdProjects[i].copyWith(racesRemaining: rem);
        }
      }
    }

    // Replenish ATR testing hours every 4 races
    if (_currentRaceIndex % 4 == 0) {
      _windTunnelHours = (_windTunnelHours + 35).clamp(0, 70);
      _cfdPoints = (_cfdPoints + 25).clamp(0, 50);
      _engineeringFeed.insert(0, '📊 FIA ATR Period Reset: Wind tunnel & CFD testing allocations replenished.');
    }

    _generateWeekendObjectives();

    notifyListeners();
    _autoSave();
  }

  void awardRaceResults({
    required Map<String, int> driverPointsGained,
    required Map<String, int> constructorPointsGained,
    int prizeMoneyMillions = 0,
    int? bestFinishPosition,
    int? longestStintLaps,
    int playerCarsFinished = 2,
  }) {
    for (var entry in driverPointsGained.entries) {
      if (_driverStandings.containsKey(entry.key)) {
        _driverStandings[entry.key] = _driverStandings[entry.key]!.copyWith(
          points: _driverStandings[entry.key]!.points + entry.value,
        );
      }
    }

    for (var entry in constructorPointsGained.entries) {
      if (_constructorStandings.containsKey(entry.key)) {
        _constructorStandings[entry.key] = _constructorStandings[entry.key]!.copyWith(
          points: _constructorStandings[entry.key]!.points + entry.value,
        );
      }
    }

    // Evaluate Board & Sponsor Objectives
    int objectivesRewardTotal = 0;
    for (int i = 0; i < _currentObjectives.length; i++) {
      final obj = _currentObjectives[i];
      bool achieved = false;
      switch (obj.type) {
        case ObjectiveType.finishPosition:
          achieved = bestFinishPosition != null && bestFinishPosition <= obj.targetValue;
          break;
        case ObjectiveType.outscoreRivalTeam:
          int myPts = constructorPointsGained[_playerTeam.id] ?? 0;
          int rivalPts = constructorPointsGained[obj.targetRivalTeamId ?? ''] ?? 0;
          achieved = myPts >= rivalPts;
          break;
        case ObjectiveType.tyreStintLength:
          achieved = longestStintLaps != null && longestStintLaps >= obj.targetValue;
          break;
        case ObjectiveType.cleanRaceNoDnf:
          achieved = playerCarsFinished >= obj.targetValue;
          break;
        default:
          achieved = bestFinishPosition != null && bestFinishPosition <= 10;
          break;
      }

      _currentObjectives[i] = obj.copyWith(isAchieved: achieved, isEvaluated: true);

      if (achieved) {
        _boardConfidence = (_boardConfidence + obj.confidenceBonus).clamp(0, 100);
        objectivesRewardTotal += obj.rewardMillions;
        _engineeringFeed.insert(
          0,
          '🎯 OBJECTIVE ACHIEVED: ${obj.title} (+\$${obj.rewardMillions}M Bonus, +${obj.confidenceBonus}% Board Confidence)',
        );
      } else {
        _boardConfidence = (_boardConfidence - obj.confidencePenalty).clamp(0, 100);
        if (obj.confidencePenalty > 0) {
          _engineeringFeed.insert(
            0,
            '⚠️ OBJECTIVE MISSED: ${obj.title} (-${obj.confidencePenalty}% Board Confidence)',
          );
        }
      }
    }

    if (bestFinishPosition != null) {
      if (bestFinishPosition == 1) {
        for (final dId in _playerTeam.driverIds) {
          _modifyDriverMorale(dId, 4);
        }
      } else if (bestFinishPosition <= 3) {
        for (final dId in _playerTeam.driverIds) {
          _modifyDriverMorale(dId, 2);
        }
      } else if (bestFinishPosition > 14) {
        for (final dId in _playerTeam.driverIds) {
          _modifyDriverMorale(dId, -2);
        }
      }
    }

    if (playerCarsFinished < 2) {
      for (final dId in _playerTeam.driverIds) {
        _modifyDriverMorale(dId, -2);
      }
    }

    int totalPayout = prizeMoneyMillions + objectivesRewardTotal;
    if (totalPayout > 0) {
      _playerTeam = _playerTeam.copyWith(
        budgetMillions: _playerTeam.budgetMillions + totalPayout,
      );
    }

    notifyListeners();
    _autoSave();
  }

  void manualSave() {
    _autoSave();
  }

  void _autoSave() {
    SaveGameService.autoSaveCareer(
      playerTeam: _playerTeam,
      currentRaceIndex: _currentRaceIndex,
      constructorStandings: _constructorStandings,
      driverStandings: _driverStandings,
      driverMorale: _driverMorale,
      boardConfidence: _boardConfidence,
    );
  }
}
