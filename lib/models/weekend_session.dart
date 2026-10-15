enum WeekendSessionType {
  practice,
  qualifying,
  race,
}

enum QualiSessionPhase {
  q1, // 20 cars, bottom 5 knocked out (P16-P20)
  q2, // 15 cars, bottom 5 knocked out (P11-P15)
  q3, // 10 cars, Pole shootout (P1-P10)
  completed,
}

class DriverQualiLap {
  final String driverId;
  final String driverShortName;
  final String teamId;
  final double lapTimeSeconds;
  final double gapToLeader;
  final bool isEliminated;
  final int finalPosition;

  const DriverQualiLap({
    required this.driverId,
    required this.driverShortName,
    required this.teamId,
    required this.lapTimeSeconds,
    required this.gapToLeader,
    this.isEliminated = false,
    required this.finalPosition,
  });

  String get formattedLapTime {
    int minutes = (lapTimeSeconds / 60).floor();
    double seconds = lapTimeSeconds - (minutes * 60);
    return '$minutes:${seconds.toStringAsFixed(3).padLeft(6, '0')}';
  }
}

class QualifyingResults {
  final List<DriverQualiLap> q1Laps;
  final List<DriverQualiLap> q2Laps;
  final List<DriverQualiLap> q3Laps;
  final List<String> startingGridDriverIds; // P1 to P20 ordered driver IDs

  const QualifyingResults({
    required this.q1Laps,
    required this.q2Laps,
    required this.q3Laps,
    required this.startingGridDriverIds,
  });
}

