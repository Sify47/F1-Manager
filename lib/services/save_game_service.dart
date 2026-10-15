import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team.dart';
import '../state/career_controller.dart';

class CareerSaveData {
  final String teamId;
  final int budgetMillions;
  final int currentRaceIndex;
  final Map<String, int> carStats;
  final Map<String, int> constructorPoints;
  final Map<String, int> driverPoints;
  final DateTime savedAt;

  CareerSaveData({
    required this.teamId,
    required this.budgetMillions,
    required this.currentRaceIndex,
    required this.carStats,
    required this.constructorPoints,
    required this.driverPoints,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'budgetMillions': budgetMillions,
        'currentRaceIndex': currentRaceIndex,
        'carStats': carStats,
        'constructorPoints': constructorPoints,
        'driverPoints': driverPoints,
        'savedAt': savedAt.toIso8601String(),
      };

  factory CareerSaveData.fromJson(Map<String, dynamic> json) {
    return CareerSaveData(
      teamId: json['teamId'] as String,
      budgetMillions: json['budgetMillions'] as int,
      currentRaceIndex: json['currentRaceIndex'] as int? ?? 0,
      carStats: Map<String, int>.from(json['carStats'] as Map? ?? {}),
      constructorPoints: Map<String, int>.from(json['constructorPoints'] as Map? ?? {}),
      driverPoints: Map<String, int>.from(json['driverPoints'] as Map? ?? {}),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SaveGameService {
  static const String _saveKey = 'f1_manager_career_save_v1';

  static Future<void> autoSaveCareer({
    required Team playerTeam,
    required int currentRaceIndex,
    required Map<String, ChampionshipStanding> constructorStandings,
    required Map<String, ChampionshipStanding> driverStandings,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final saveData = CareerSaveData(
        teamId: playerTeam.id,
        budgetMillions: playerTeam.budgetMillions,
        currentRaceIndex: currentRaceIndex,
        carStats: {
          'topSpeed': playerTeam.car.topSpeed,
          'acceleration': playerTeam.car.acceleration,
          'highSpeedDownforce': playerTeam.car.highSpeedDownforce,
          'mediumSpeedDownforce': playerTeam.car.mediumSpeedDownforce,
          'lowSpeedDownforce': playerTeam.car.lowSpeedDownforce,
          'tyrePreservation': playerTeam.car.tyrePreservation,
          'drsEfficiency': playerTeam.car.drsEfficiency,
          'reliability': playerTeam.car.reliability,
        },
        constructorPoints: constructorStandings.map((k, v) => MapEntry(k, v.points)),
        driverPoints: driverStandings.map((k, v) => MapEntry(k, v.points)),
        savedAt: DateTime.now(),
      );

      final jsonStr = jsonEncode(saveData.toJson());
      await prefs.setString(_saveKey, jsonStr);
    } catch (e) {
      // Safe fallback
    }
  }

  static Future<CareerSaveData?> loadSavedCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_saveKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return CareerSaveData.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasSavedCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_saveKey);
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_saveKey);
    } catch (_) {}
  }
}
