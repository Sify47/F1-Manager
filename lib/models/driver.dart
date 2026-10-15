class DriverStats {
  // Mechanical Vehicle Control (0 - 100)
  final int braking;           // Precision braking, late braking, anti-lockup control
  final int corneringSlow;     // Hairpins, tight chicanes, slow chicane traction
  final int corneringMedium;   // 90-degree technical bends, mid-speed transitions
  final int corneringFast;     // High downforce sweeping corners (Copse, Eau Rouge, Pouhon)
  final int reactions;         // Starts, incident avoidance, rapid direction changes

  // Racecraft & Strategy (0 - 100)
  final int overtaking;        // Finding gaps, DRS pass execution, late dive-bombs
  final int defending;         // Positioning, blocking inside line, slipstream breaking
  final int tyreManagement;    // Minimizing thermal and graining degradation
  final int wetWeatherSkill;   // Pace and stability in damp / wet conditions

  // Psychology & Mental (0 - 100)
  final int composure;         // Resistance to pressure, mistakes under stress
  final int consistency;       // Lap-to-lap variance reduction
  final int ego;               // Higher ego means more likely to question/defy team orders
  final int morale;            // Current happiness and confidence (0 - 100)

  const DriverStats({
    required this.braking,
    required this.corneringSlow,
    required this.corneringMedium,
    required this.corneringFast,
    required this.reactions,
    required this.overtaking,
    required this.defending,
    required this.tyreManagement,
    required this.wetWeatherSkill,
    required this.composure,
    required this.consistency,
    this.ego = 70,
    this.morale = 85,
  });

  int get overallRating {
    return ((braking * 1.2 +
            corneringSlow * 1.0 +
            corneringMedium * 1.0 +
            corneringFast * 1.2 +
            reactions * 0.9 +
            overtaking * 1.1 +
            defending * 1.0 +
            tyreManagement * 1.1 +
            wetWeatherSkill * 0.8 +
            composure * 1.0 +
            consistency * 1.1) /
        11.4).round();
  }

  DriverStats copyWith({
    int? braking,
    int? corneringSlow,
    int? corneringMedium,
    int? corneringFast,
    int? reactions,
    int? overtaking,
    int? defending,
    int? tyreManagement,
    int? wetWeatherSkill,
    int? composure,
    int? consistency,
    int? ego,
    int? morale,
  }) {
    return DriverStats(
      braking: braking ?? this.braking,
      corneringSlow: corneringSlow ?? this.corneringSlow,
      corneringMedium: corneringMedium ?? this.corneringMedium,
      corneringFast: corneringFast ?? this.corneringFast,
      reactions: reactions ?? this.reactions,
      overtaking: overtaking ?? this.overtaking,
      defending: defending ?? this.defending,
      tyreManagement: tyreManagement ?? this.tyreManagement,
      wetWeatherSkill: wetWeatherSkill ?? this.wetWeatherSkill,
      composure: composure ?? this.composure,
      consistency: consistency ?? this.consistency,
      ego: ego ?? this.ego,
      morale: morale ?? this.morale,
    );
  }
}

class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String shortCode; // E.g., 'VER', 'HAM', 'NOR', 'LEC'
  final int number;       // Driver permanent number (1, 44, 16, 4, etc.)
  final String country;
  final String nationalityCode; // 'NLD', 'GBR', 'MON', 'ESP', etc.
  final int age;
  final String teamId;
  final int salaryMillions; // Annual salary in millions of $
  final int contractYearsRemaining;
  final DriverStats stats;

  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.shortCode,
    required this.number,
    required this.country,
    required this.nationalityCode,
    required this.age,
    required this.teamId,
    required this.salaryMillions,
    required this.contractYearsRemaining,
    required this.stats,
  });

  String get fullName => '$firstName $lastName';

  Driver copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? shortCode,
    int? number,
    String? country,
    String? nationalityCode,
    int? age,
    String? teamId,
    int? salaryMillions,
    int? contractYearsRemaining,
    DriverStats? stats,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      shortCode: shortCode ?? this.shortCode,
      number: number ?? this.number,
      country: country ?? this.country,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      age: age ?? this.age,
      teamId: teamId ?? this.teamId,
      salaryMillions: salaryMillions ?? this.salaryMillions,
      contractYearsRemaining: contractYearsRemaining ?? this.contractYearsRemaining,
      stats: stats ?? this.stats,
    );
  }
}

