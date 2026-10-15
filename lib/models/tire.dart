enum TireType {
  soft,
  medium,
  hard,
  intermediate,
  wet,
}

class TireCompound {
  final TireType type;
  final String name;
  final String shortCode;
  final int colorHex;
  final double basePaceAdvantage; // Delta in seconds per lap compared to base (Soft is fastest)
  final double wearRatePerLap;    // Base wear percentage per lap (0.0 to 1.0)
  final double cliffThreshold;    // Percentage wear after which lap times drastically drop
  final double optimalMinTrackTemp;
  final double optimalMaxTrackTemp;
  final double optimalMinRain;
  final double optimalMaxRain;

  const TireCompound({
    required this.type,
    required this.name,
    required this.shortCode,
    required this.colorHex,
    required this.basePaceAdvantage,
    required this.wearRatePerLap,
    required this.cliffThreshold,
    required this.optimalMinTrackTemp,
    required this.optimalMaxTrackTemp,
    required this.optimalMinRain,
    required this.optimalMaxRain,
  });

  static const TireCompound soft = TireCompound(
    type: TireType.soft,
    name: 'Soft (C4/C5)',
    shortCode: 'S',
    colorHex: 0xFFE10600, // F1 Red
    basePaceAdvantage: -0.9, // 0.9s faster than Medium initially
    wearRatePerLap: 0.048,   // ~20-25 laps lifespan
    cliffThreshold: 0.70,   // Cliff at 70% wear
    optimalMinTrackTemp: 25.0,
    optimalMaxTrackTemp: 45.0,
    optimalMinRain: 0.0,
    optimalMaxRain: 0.1,
  );

  static const TireCompound medium = TireCompound(
    type: TireType.medium,
    name: 'Medium (C3)',
    shortCode: 'M',
    colorHex: 0xFFFFD700, // F1 Yellow
    basePaceAdvantage: 0.0,  // Baseline
    wearRatePerLap: 0.030,   // ~33 laps lifespan
    cliffThreshold: 0.75,
    optimalMinTrackTemp: 20.0,
    optimalMaxTrackTemp: 50.0,
    optimalMinRain: 0.0,
    optimalMaxRain: 0.1,
  );

  static const TireCompound hard = TireCompound(
    type: TireType.hard,
    name: 'Hard (C1/C2)',
    shortCode: 'H',
    colorHex: 0xFFFFFFFF, // F1 White
    basePaceAdvantage: 0.8,  // 0.8s slower than Medium initially
    wearRatePerLap: 0.018,   // ~55 laps lifespan
    cliffThreshold: 0.82,
    optimalMinTrackTemp: 22.0,
    optimalMaxTrackTemp: 55.0,
    optimalMinRain: 0.0,
    optimalMaxRain: 0.1,
  );

  static const TireCompound intermediate = TireCompound(
    type: TireType.intermediate,
    name: 'Intermediate',
    shortCode: 'I',
    colorHex: 0xFF00D2BE, // F1 Green
    basePaceAdvantage: 3.5,  // Slower on dry, fast on damp
    wearRatePerLap: 0.040,
    cliffThreshold: 0.75,
    optimalMinTrackTemp: 15.0,
    optimalMaxTrackTemp: 35.0,
    optimalMinRain: 0.15,
    optimalMaxRain: 0.60,
  );

  static const TireCompound wet = TireCompound(
    type: TireType.wet,
    name: 'Full Wet',
    shortCode: 'W',
    colorHex: 0xFF0090FF, // F1 Blue
    basePaceAdvantage: 7.0,
    wearRatePerLap: 0.035,
    cliffThreshold: 0.80,
    optimalMinTrackTemp: 12.0,
    optimalMaxTrackTemp: 30.0,
    optimalMinRain: 0.55,
    optimalMaxRain: 1.0,
  );

  static TireCompound fromType(TireType type) {
    switch (type) {
      case TireType.soft:
        return soft;
      case TireType.medium:
        return medium;
      case TireType.hard:
        return hard;
      case TireType.intermediate:
        return intermediate;
      case TireType.wet:
        return wet;
    }
  }
}

