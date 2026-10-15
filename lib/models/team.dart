class CarPerformance {
  final int topSpeed;              // Engine power & drag efficiency on straights (0-100)
  final int acceleration;          // ERS & low gear traction out of corners (0-100)
  final int lowSpeedDownforce;     // Downforce in tight turns & hairpins (0-100)
  final int mediumSpeedDownforce;  // Technical turns (0-100)
  final int highSpeedDownforce;    // Sweeping bends (Copse, Becketts, 130R) (0-100)
  final int drsEfficiency;         // Drag reduction system delta when open (0-100)
  final int tyrePreservation;      // Car chassis friendliness to tires (0-100)
  final int reliability;           // Mechanical endurance against DNF/PU issues (0-100)

  const CarPerformance({
    required this.topSpeed,
    required this.acceleration,
    required this.lowSpeedDownforce,
    required this.mediumSpeedDownforce,
    required this.highSpeedDownforce,
    required this.drsEfficiency,
    required this.tyrePreservation,
    required this.reliability,
  });

  int get overallRating {
    return ((topSpeed * 1.2 +
            acceleration * 1.1 +
            lowSpeedDownforce * 1.0 +
            mediumSpeedDownforce * 1.0 +
            highSpeedDownforce * 1.2 +
            drsEfficiency * 0.8 +
            tyrePreservation * 1.0 +
            reliability * 0.9) /
        8.2).round();
  }

  CarPerformance copyWith({
    int? topSpeed,
    int? acceleration,
    int? lowSpeedDownforce,
    int? mediumSpeedDownforce,
    int? highSpeedDownforce,
    int? drsEfficiency,
    int? tyrePreservation,
    int? reliability,
  }) {
    return CarPerformance(
      topSpeed: topSpeed ?? this.topSpeed,
      acceleration: acceleration ?? this.acceleration,
      lowSpeedDownforce: lowSpeedDownforce ?? this.lowSpeedDownforce,
      mediumSpeedDownforce: mediumSpeedDownforce ?? this.mediumSpeedDownforce,
      highSpeedDownforce: highSpeedDownforce ?? this.highSpeedDownforce,
      drsEfficiency: drsEfficiency ?? this.drsEfficiency,
      tyrePreservation: tyrePreservation ?? this.tyrePreservation,
      reliability: reliability ?? this.reliability,
    );
  }
}

class TeamFacilities {
  final int windTunnelLevel;      // Aero upgrade boost (1 - 5)
  final int cfdSupercomputer;     // Aero simulation accuracy (1 - 5)
  final int simulatorLevel;       // Driver setup preparation (1 - 5)
  final int designOfficeLevel;    // Part development speed (1 - 5)
  final int pitCrewGymLevel;      // Pit stop speed & error reduction (1 - 5)

  const TeamFacilities({
    this.windTunnelLevel = 3,
    this.cfdSupercomputer = 3,
    this.simulatorLevel = 3,
    this.designOfficeLevel = 3,
    this.pitCrewGymLevel = 3,
  });
}

class Team {
  final String id;
  final String name;
  final String shortName;
  final String principalName;
  final int primaryColorHex;
  final int secondaryColorHex;
  final String engineManufacturer; // E.g., 'Honda RBPT', 'Ferrari', 'Mercedes', 'Renault'
  final int budgetMillions;        // Budget cap / available cash in $M
  final List<String> driverIds;    // 2 main drivers
  final CarPerformance car;
  final TeamFacilities facilities;

  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.principalName,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.engineManufacturer,
    required this.budgetMillions,
    required this.driverIds,
    required this.car,
    this.facilities = const TeamFacilities(),
  });

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    String? principalName,
    int? primaryColorHex,
    int? secondaryColorHex,
    String? engineManufacturer,
    int? budgetMillions,
    List<String>? driverIds,
    CarPerformance? car,
    TeamFacilities? facilities,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      principalName: principalName ?? this.principalName,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      engineManufacturer: engineManufacturer ?? this.engineManufacturer,
      budgetMillions: budgetMillions ?? this.budgetMillions,
      driverIds: driverIds ?? this.driverIds,
      car: car ?? this.car,
      facilities: facilities ?? this.facilities,
    );
  }
}

