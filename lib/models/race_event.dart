enum SafetyCarStatus {
  clear,
  virtualSafetyCar,
  fullSafetyCar,
  redFlag,
}

enum EventSeverity {
  info,
  good,
  warning,
  critical,
}

enum RadioSender {
  driver,
  raceEngineer,
  teamPrincipal,
  raceControl,
  chiefStrategist,
}

class RadioMessage {
  final String id;
  final String driverId;
  final String driverShortName;
  final RadioSender sender;
  final String text;
  final int lap;
  final DateTime timestamp;
  final bool requiresAction;
  final List<String>? actionOptions;

  const RadioMessage({
    required this.id,
    required this.driverId,
    required this.driverShortName,
    required this.sender,
    required this.text,
    required this.lap,
    required this.timestamp,
    this.requiresAction = false,
    this.actionOptions,
  });
}

class RaceEvent {
  final String id;
  final int lap;
  final int sector;
  final String title;
  final String description;
  final EventSeverity severity;
  final String? driverId;
  final String? targetDriverId;
  final DateTime timestamp;

  const RaceEvent({
    required this.id,
    required this.lap,
    required this.sector,
    required this.title,
    required this.description,
    required this.severity,
    this.driverId,
    this.targetDriverId,
    required this.timestamp,
  });
}

class BattleActionCard {
  final String id;
  final int lap;
  final String attackerDriverId;
  final String defenderDriverId;
  final String headline;
  final String detail;
  final bool isSuccessfulOvertake;

  const BattleActionCard({
    required this.id,
    required this.lap,
    required this.attackerDriverId,
    required this.defenderDriverId,
    required this.headline,
    required this.detail,
    required this.isSuccessfulOvertake,
  });
}

