enum CornerSpeedType {
  slow,    // Hairpins, tight chicanes (requires mechanical grip & driver slow corner skill)
  medium,  // 90-degree technical bends (requires balance)
  fast,    // High-speed sweeps (Eau Rouge, Copse, 130R - requires downforce & brave braking)
  straight // Long straights / full throttle DRS zones
}

class TrackCorner {
  final int cornerNumber;
  final String? name;
  final CornerSpeedType type;
  final bool isDrsZone;
  final double lengthKm;

  const TrackCorner({
    required this.cornerNumber,
    this.name,
    required this.type,
    this.isDrsZone = false,
    required this.lengthKm,
  });
}

class TrackSector {
  final int sectorNumber; // 1, 2, or 3
  final double lengthKm;
  final List<TrackCorner> corners;
  final double baseBenchmarkSeconds;

  const TrackSector({
    required this.sectorNumber,
    required this.lengthKm,
    required this.corners,
    required this.baseBenchmarkSeconds,
  });

  int countCorners(CornerSpeedType type) {
    return corners.where((c) => c.type == type).length;
  }
}

class Circuit {
  final String id;
  final String name;
  final String grandPrixName;
  final String country;
  final String flagEmoji;
  final String city;
  final double lengthKm;
  final int totalLaps;
  final double baseLapRecordSeconds;
  final double asphaltAbrasiveness;      // 0.0 (smooth like Monaco) to 1.0 (harsh like Bahrain/Silverstone)
  final double overtakingDifficulty;     // 0.0 (easy like Spa/Monza) to 1.0 (near impossible like Monaco)
  final double pitLaneLossSeconds;       // Total time lost driving through pit lane at speed limiter (~18-25s)
  final double baseRainProbability;      // 0.0 to 1.0
  final double baseTrackTemperature;     // Celsius
  final List<TrackSector> sectors;
  final int drsZonesCount;
  final bool isSprintWeekend;

  const Circuit({
    required this.id,
    required this.name,
    required this.grandPrixName,
    required this.country,
    required this.flagEmoji,
    required this.city,
    required this.lengthKm,
    required this.totalLaps,
    required this.baseLapRecordSeconds,
    required this.asphaltAbrasiveness,
    required this.overtakingDifficulty,
    required this.pitLaneLossSeconds,
    required this.baseRainProbability,
    required this.baseTrackTemperature,
    required this.sectors,
    required this.drsZonesCount,
    this.isSprintWeekend = false,
  });

  double get raceDistanceKm => lengthKm * totalLaps;
  int get sprintLaps => (totalLaps / 3.0).round();
}

