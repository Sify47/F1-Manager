import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/circuit.dart';
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

  CareerController({Team? initialTeam, CareerSaveData? savedData})
      : _playerTeam = initialTeam ?? TeamsData.allTeams.first,
        _calendar = CircuitsData.allCircuits {
    if (savedData != null) {
      _restoreFromSave(savedData);
    } else {
      _initializeStandings();
    }
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
    }
  }

  // R&D Upgrade methods
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
    notifyListeners();
    _autoSave();
  }

  void awardRaceResults({
    required Map<String, int> driverPointsGained,
    required Map<String, int> constructorPointsGained,
    int prizeMoneyMillions = 0,
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

    if (prizeMoneyMillions > 0) {
      _playerTeam = _playerTeam.copyWith(
        budgetMillions: _playerTeam.budgetMillions + prizeMoneyMillions,
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
    );
  }
}
