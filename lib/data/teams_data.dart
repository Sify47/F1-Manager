import '../models/team.dart';

class TeamsData {
  static const List<Team> allTeams = [
    // RED BULL RACING
    Team(
      id: 'red_bull',
      name: 'Oracle Red Bull Racing',
      shortName: 'Red Bull',
      principalName: 'Christian Horner',
      primaryColorHex: 0xFF1E41FF,   // Navy Blue
      secondaryColorHex: 0xFFF50028, // Red / Yellow accent
      engineManufacturer: 'Honda RBPT',
      budgetMillions: 135,
      driverIds: ['max_verstappen', 'sergio_perez'],
      car: CarPerformance(
        topSpeed: 96,
        acceleration: 97,
        lowSpeedDownforce: 94,
        mediumSpeedDownforce: 96,
        highSpeedDownforce: 97,
        drsEfficiency: 98,
        tyrePreservation: 95,
        reliability: 96,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 5,
        cfdSupercomputer: 5,
        simulatorLevel: 5,
        designOfficeLevel: 5,
        pitCrewGymLevel: 5,
      ),
    ),

    // FERRARI
    Team(
      id: 'ferrari',
      name: 'Scuderia Ferrari',
      shortName: 'Ferrari',
      principalName: 'Frédéric Vasseur',
      primaryColorHex: 0xFFE8002D, // Ferrari Rosso Corsa
      secondaryColorHex: 0xFFFFEB00, // Modena Yellow
      engineManufacturer: 'Ferrari',
      budgetMillions: 135,
      driverIds: ['charles_leclerc', 'carlos_sainz'],
      car: CarPerformance(
        topSpeed: 97,
        acceleration: 96,
        lowSpeedDownforce: 96,
        mediumSpeedDownforce: 94,
        highSpeedDownforce: 94,
        drsEfficiency: 95,
        tyrePreservation: 91,
        reliability: 93,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 5,
        cfdSupercomputer: 5,
        simulatorLevel: 5,
        designOfficeLevel: 5,
        pitCrewGymLevel: 4,
      ),
    ),

    // MCLAREN
    Team(
      id: 'mclaren',
      name: 'McLaren F1 Team',
      shortName: 'McLaren',
      principalName: 'Andrea Stella',
      primaryColorHex: 0xFFFF8000, // Papaya Orange
      secondaryColorHex: 0xFF47C7FC, // Anthracite / Sky
      engineManufacturer: 'Mercedes',
      budgetMillions: 135,
      driverIds: ['lando_norris', 'oscar_piastri'],
      car: CarPerformance(
        topSpeed: 94,
        acceleration: 96,
        lowSpeedDownforce: 94,
        mediumSpeedDownforce: 97,
        highSpeedDownforce: 98, // Monster in high speed
        drsEfficiency: 94,
        tyrePreservation: 94,
        reliability: 95,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 5,
        cfdSupercomputer: 5,
        simulatorLevel: 5,
        designOfficeLevel: 5,
        pitCrewGymLevel: 5,
      ),
    ),

    // MERCEDES
    Team(
      id: 'mercedes',
      name: 'Mercedes-AMG PETRONAS F1 Team',
      shortName: 'Mercedes',
      principalName: 'Toto Wolff',
      primaryColorHex: 0xFF00D2BE, // Petronas Cyan
      secondaryColorHex: 0xFF000000, // Silver Arrow / Black
      engineManufacturer: 'Mercedes',
      budgetMillions: 135,
      driverIds: ['lewis_hamilton', 'george_russell'],
      car: CarPerformance(
        topSpeed: 93,
        acceleration: 94,
        lowSpeedDownforce: 92,
        mediumSpeedDownforce: 93,
        highSpeedDownforce: 93,
        drsEfficiency: 93,
        tyrePreservation: 92,
        reliability: 97,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 5,
        cfdSupercomputer: 5,
        simulatorLevel: 5,
        designOfficeLevel: 5,
        pitCrewGymLevel: 4,
      ),
    ),

    // ASTON MARTIN
    Team(
      id: 'aston_martin',
      name: 'Aston Martin Aramco F1 Team',
      shortName: 'Aston Martin',
      principalName: 'Mike Krack',
      primaryColorHex: 0xFF229971, // British Racing Green
      secondaryColorHex: 0xFFCEDC00, // Lime
      engineManufacturer: 'Mercedes',
      budgetMillions: 120,
      driverIds: ['fernando_alonso', 'lance_stroll'],
      car: CarPerformance(
        topSpeed: 91,
        acceleration: 92,
        lowSpeedDownforce: 90,
        mediumSpeedDownforce: 90,
        highSpeedDownforce: 89,
        drsEfficiency: 90,
        tyrePreservation: 88,
        reliability: 92,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 4,
        cfdSupercomputer: 4,
        simulatorLevel: 4,
        designOfficeLevel: 4,
        pitCrewGymLevel: 3,
      ),
    ),

    // RB (RACING BULLS)
    Team(
      id: 'rb',
      name: 'Visa Cash App RB F1 Team',
      shortName: 'RB',
      principalName: 'Laurent Mekies',
      primaryColorHex: 0xFF6692FF, // Electric Blue
      secondaryColorHex: 0xFFFFFFFF,
      engineManufacturer: 'Honda RBPT',
      budgetMillions: 110,
      driverIds: ['yuki_tsunoda', 'daniel_ricciardo'],
      car: CarPerformance(
        topSpeed: 89,
        acceleration: 89,
        lowSpeedDownforce: 88,
        mediumSpeedDownforce: 87,
        highSpeedDownforce: 87,
        drsEfficiency: 89,
        tyrePreservation: 87,
        reliability: 91,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 3,
        cfdSupercomputer: 3,
        simulatorLevel: 3,
        designOfficeLevel: 3,
        pitCrewGymLevel: 3,
      ),
    ),

    // HAAS
    Team(
      id: 'haas',
      name: 'MoneyGram Haas F1 Team',
      shortName: 'Haas',
      principalName: 'Ayao Komatsu',
      primaryColorHex: 0xFFB6BABD, // Haas Grey/White
      secondaryColorHex: 0xFFE10600, // Red
      engineManufacturer: 'Ferrari',
      budgetMillions: 105,
      driverIds: ['nico_hulkenberg', 'kevin_magnussen'],
      car: CarPerformance(
        topSpeed: 91,
        acceleration: 88,
        lowSpeedDownforce: 87,
        mediumSpeedDownforce: 86,
        highSpeedDownforce: 86,
        drsEfficiency: 91,
        tyrePreservation: 85, // Historically eats tires
        reliability: 90,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 3,
        cfdSupercomputer: 3,
        simulatorLevel: 3,
        designOfficeLevel: 3,
        pitCrewGymLevel: 3,
      ),
    ),

    // WILLIAMS
    Team(
      id: 'williams',
      name: 'Williams Racing',
      shortName: 'Williams',
      principalName: 'James Vowles',
      primaryColorHex: 0xFF041E42, // Heritage Blue
      secondaryColorHex: 0xFF00A0DE, // Light Blue
      engineManufacturer: 'Mercedes',
      budgetMillions: 105,
      driverIds: ['alex_albon', 'franco_colapinto'],
      car: CarPerformance(
        topSpeed: 94, // Straight-line rocket
        acceleration: 89,
        lowSpeedDownforce: 85,
        mediumSpeedDownforce: 86,
        highSpeedDownforce: 86,
        drsEfficiency: 93,
        tyrePreservation: 86,
        reliability: 92,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 3,
        cfdSupercomputer: 3,
        simulatorLevel: 3,
        designOfficeLevel: 3,
        pitCrewGymLevel: 3,
      ),
    ),

    // ALPINE
    Team(
      id: 'alpine',
      name: 'BWT Alpine F1 Team',
      shortName: 'Alpine',
      principalName: 'Oliver Oakes',
      primaryColorHex: 0xFF0090FF, // Alpine Blue
      secondaryColorHex: 0xFFFF87BC, // BWT Pink
      engineManufacturer: 'Renault',
      budgetMillions: 115,
      driverIds: ['pierre_gasly', 'esteban_ocon'],
      car: CarPerformance(
        topSpeed: 87,
        acceleration: 87,
        lowSpeedDownforce: 87,
        mediumSpeedDownforce: 87,
        highSpeedDownforce: 86,
        drsEfficiency: 87,
        tyrePreservation: 87,
        reliability: 88,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 3,
        cfdSupercomputer: 3,
        simulatorLevel: 3,
        designOfficeLevel: 3,
        pitCrewGymLevel: 3,
      ),
    ),

    // STAKE SAUBER
    Team(
      id: 'sauber',
      name: 'Stake F1 Team Kick Sauber',
      shortName: 'Sauber',
      principalName: 'Mattia Binotto',
      primaryColorHex: 0xFF52E252, // Fluro Neon Green
      secondaryColorHex: 0xFF000000, // Black
      engineManufacturer: 'Ferrari',
      budgetMillions: 100,
      driverIds: ['valtteri_bottas', 'zhou_guanyu'],
      car: CarPerformance(
        topSpeed: 86,
        acceleration: 86,
        lowSpeedDownforce: 85,
        mediumSpeedDownforce: 85,
        highSpeedDownforce: 84,
        drsEfficiency: 86,
        tyrePreservation: 85,
        reliability: 87,
      ),
      facilities: TeamFacilities(
        windTunnelLevel: 3,
        cfdSupercomputer: 3,
        simulatorLevel: 3,
        designOfficeLevel: 3,
        pitCrewGymLevel: 2, // Infamous pit stop wheel nut issues
      ),
    ),
  ];

  static Team? getTeamById(String id) {
    try {
      return allTeams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

