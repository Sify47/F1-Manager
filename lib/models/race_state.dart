import 'tire.dart';

enum PaceMode {
  conserve, // -0.8s pace, -40% tire wear, fuel saving
  balanced, // standard baseline
  push,     // +0.6s pace, +35% tire wear, normal fuel
  attack,   // +1.1s pace, +80% tire wear, high fuel consumption, risk of error
}

enum FuelMix {
  lean,     // Saves fuel, -0.4s pace
  standard, // Balanced
  rich,     // Burns fuel fast, +0.5s pace
}

enum ErsMode {
  charge,   // Recharges battery, -0.7s pace
  balanced, // Neutral deployment
  deploy,   // Full deployment out of turns, +0.6s pace
  overtake, // Maximum dump of battery, +1.2s pace (drains quickly)
}

enum CarRaceStatus {
  racing,
  inPitLane,
  pitting,
  outOfRace, // DNF
}

class CarTelemetry {
  final String driverId;
  final String teamId;
  final int position;
  final int startingPosition;
  final int currentLap;
  final int currentSector; // 1, 2, 3
  final double sectorProgress; // 0.0 to 1.0 within the sector
  final double trackDistanceTravelledKm;
  
  // Timing
  final double lastLapTime;
  final double bestLapTime;
  final double currentLapTime;
  final double gapToLeaderSeconds;
  final double intervalToAheadSeconds;
  final List<double> sector1Times;
  final List<double> sector2Times;
  final List<double> sector3Times;

  // Car mechanical state
  final TireCompound currentTire;
  final double tireWearPercentage; // 0.0 (new) to 1.0 (dead)
  final double tireTemperature;    // Celsius (~85-115 optimum)
  final double fuelRemainingKg;
  final double ersBatteryPercentage; // 0.0 to 1.0
  final double wingDamagePercentage; // 0.0 to 1.0
  final int pitStopsCount;
  final int lapsOnCurrentTire;

  // Active Driver Commands
  final PaceMode paceMode;
  final FuelMix fuelMix;
  final ErsMode ersMode;
  final bool boxThisLap;
  final TireType? nextPitTire;
  final bool repairWingInPit;

  // Status & Telemetry
  final CarRaceStatus status;
  final String? dnfReason;
  final bool hasDrsAvailable;
  final double driverConfidence; // 0.0 to 1.0

  const CarTelemetry({
    required this.driverId,
    required this.teamId,
    required this.position,
    required this.startingPosition,
    required this.currentLap,
    required this.currentSector,
    required this.sectorProgress,
    required this.trackDistanceTravelledKm,
    required this.lastLapTime,
    required this.bestLapTime,
    required this.currentLapTime,
    required this.gapToLeaderSeconds,
    required this.intervalToAheadSeconds,
    required this.sector1Times,
    required this.sector2Times,
    required this.sector3Times,
    required this.currentTire,
    required this.tireWearPercentage,
    required this.tireTemperature,
    required this.fuelRemainingKg,
    required this.ersBatteryPercentage,
    required this.wingDamagePercentage,
    required this.pitStopsCount,
    required this.lapsOnCurrentTire,
    required this.paceMode,
    required this.fuelMix,
    required this.ersMode,
    required this.boxThisLap,
    this.nextPitTire,
    this.repairWingInPit = false,
    required this.status,
    this.dnfReason,
    required this.hasDrsAvailable,
    required this.driverConfidence,
  });

  CarTelemetry copyWith({
    String? driverId,
    String? teamId,
    int? position,
    int? startingPosition,
    int? currentLap,
    int? currentSector,
    double? sectorProgress,
    double? trackDistanceTravelledKm,
    double? lastLapTime,
    double? bestLapTime,
    double? currentLapTime,
    double? gapToLeaderSeconds,
    double? intervalToAheadSeconds,
    List<double>? sector1Times,
    List<double>? sector2Times,
    List<double>? sector3Times,
    TireCompound? currentTire,
    double? tireWearPercentage,
    double? tireTemperature,
    double? fuelRemainingKg,
    double? ersBatteryPercentage,
    double? wingDamagePercentage,
    int? pitStopsCount,
    int? lapsOnCurrentTire,
    PaceMode? paceMode,
    FuelMix? fuelMix,
    ErsMode? ersMode,
    bool? boxThisLap,
    TireType? nextPitTire,
    bool? repairWingInPit,
    CarRaceStatus? status,
    String? dnfReason,
    bool? hasDrsAvailable,
    double? driverConfidence,
  }) {
    return CarTelemetry(
      driverId: driverId ?? this.driverId,
      teamId: teamId ?? this.teamId,
      position: position ?? this.position,
      startingPosition: startingPosition ?? this.startingPosition,
      currentLap: currentLap ?? this.currentLap,
      currentSector: currentSector ?? this.currentSector,
      sectorProgress: sectorProgress ?? this.sectorProgress,
      trackDistanceTravelledKm: trackDistanceTravelledKm ?? this.trackDistanceTravelledKm,
      lastLapTime: lastLapTime ?? this.lastLapTime,
      bestLapTime: bestLapTime ?? this.bestLapTime,
      currentLapTime: currentLapTime ?? this.currentLapTime,
      gapToLeaderSeconds: gapToLeaderSeconds ?? this.gapToLeaderSeconds,
      intervalToAheadSeconds: intervalToAheadSeconds ?? this.intervalToAheadSeconds,
      sector1Times: sector1Times ?? this.sector1Times,
      sector2Times: sector2Times ?? this.sector2Times,
      sector3Times: sector3Times ?? this.sector3Times,
      currentTire: currentTire ?? this.currentTire,
      tireWearPercentage: tireWearPercentage ?? this.tireWearPercentage,
      tireTemperature: tireTemperature ?? this.tireTemperature,
      fuelRemainingKg: fuelRemainingKg ?? this.fuelRemainingKg,
      ersBatteryPercentage: ersBatteryPercentage ?? this.ersBatteryPercentage,
      wingDamagePercentage: wingDamagePercentage ?? this.wingDamagePercentage,
      pitStopsCount: pitStopsCount ?? this.pitStopsCount,
      lapsOnCurrentTire: lapsOnCurrentTire ?? this.lapsOnCurrentTire,
      paceMode: paceMode ?? this.paceMode,
      fuelMix: fuelMix ?? this.fuelMix,
      ersMode: ersMode ?? this.ersMode,
      boxThisLap: boxThisLap ?? this.boxThisLap,
      nextPitTire: nextPitTire ?? this.nextPitTire,
      repairWingInPit: repairWingInPit ?? this.repairWingInPit,
      status: status ?? this.status,
      dnfReason: dnfReason ?? this.dnfReason,
      hasDrsAvailable: hasDrsAvailable ?? this.hasDrsAvailable,
      driverConfidence: driverConfidence ?? this.driverConfidence,
    );
  }

  bool get isInDirtyAir => intervalToAheadSeconds > 0.0 && intervalToAheadSeconds <= 1.2;
  bool get isInSlipstream => intervalToAheadSeconds > 0.0 && intervalToAheadSeconds <= 0.8;
}

