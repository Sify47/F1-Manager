enum CarPartType {
  frontWing,
  rearWing,
  underfloor,
  sidepodsCooling,
  suspensionBrakes,
  powerUnit,
  pitEquipment,
}

extension CarPartTypeExtension on CarPartType {
  String get displayName {
    switch (this) {
      case CarPartType.frontWing:
        return 'Front Wing & Flaps';
      case CarPartType.rearWing:
        return 'Rear Wing & Beam Wing';
      case CarPartType.underfloor:
        return 'Ground Effect Floor';
      case CarPartType.sidepodsCooling:
        return 'Sidepods & Cooling Louvres';
      case CarPartType.suspensionBrakes:
        return 'Suspension & Carbon Brakes';
      case CarPartType.powerUnit:
        return 'Power Unit & MGU-K Hybrid';
      case CarPartType.pitEquipment:
        return 'Pit Stop Wheel Guns & Jacks';
    }
  }

  String get department {
    switch (this) {
      case CarPartType.frontWing:
      case CarPartType.rearWing:
      case CarPartType.underfloor:
        return 'AERODYNAMICS DEPT';
      case CarPartType.sidepodsCooling:
      case CarPartType.suspensionBrakes:
        return 'CHASSIS & MECHANICAL DEPT';
      case CarPartType.powerUnit:
        return 'POWERTRAIN DEPT';
      case CarPartType.pitEquipment:
        return 'PIT CREW OPERATIONS';
    }
  }
}

class RdSpecPhilosophy {
  final String id;
  final String name;
  final String description;
  final String prosText;
  final String consText;
  final Map<String, int> statDeltas;
  final int baseCostMillions;
  final int baseRacesToDeliver;

  const RdSpecPhilosophy({
    required this.id,
    required this.name,
    required this.description,
    required this.prosText,
    required this.consText,
    required this.statDeltas,
    required this.baseCostMillions,
    required this.baseRacesToDeliver,
  });
}

class CarPartRdCatalog {
  static List<RdSpecPhilosophy> getSpecsForPart(CarPartType partType) {
    switch (partType) {
      case CarPartType.frontWing:
        return const [
          RdSpecPhilosophy(
            id: 'fw_high_downforce',
            name: 'High-Downforce Flap Extension',
            description: 'Aggressive flap angle for sharp low and medium speed turn-in grip.',
            prosText: '+4 Low-Speed Downforce, +3 Medium-Speed Downforce',
            consText: '-2 Top Speed on straights due to induced aerodynamic drag',
            statDeltas: {
              'lowSpeedDownforce': 4,
              'mediumSpeedDownforce': 3,
              'topSpeed': -2,
            },
            baseCostMillions: 6,
            baseRacesToDeliver: 1,
          ),
          RdSpecPhilosophy(
            id: 'fw_low_drag',
            name: 'Low-Drag Endplate Outwash',
            description: 'Optimized outwash flow diverting turbulent air outward around the wheels.',
            prosText: '+3 Top Speed, +2 DRS Efficiency',
            consText: '-2 Low-Speed cornering bite',
            statDeltas: {
              'topSpeed': 3,
              'drsEfficiency': 2,
              'lowSpeedDownforce': -2,
            },
            baseCostMillions: 5,
            baseRacesToDeliver: 1,
          ),
          RdSpecPhilosophy(
            id: 'fw_balanced_inwash',
            name: 'Balanced Inwash Evolution',
            description: 'Refined aero balance providing smooth load across all yaw angles.',
            prosText: '+2 Low-Speed Downforce, +2 Top Speed',
            consText: 'Higher design iteration cycle time',
            statDeltas: {
              'lowSpeedDownforce': 2,
              'topSpeed': 2,
            },
            baseCostMillions: 7,
            baseRacesToDeliver: 2,
          ),
        ];

      case CarPartType.rearWing:
        return const [
          RdSpecPhilosophy(
            id: 'rw_monza_skinny',
            name: 'Ultra Low-Drag Beam Wing',
            description: 'Spoon profile rear wing with minimal frontal area for maximum straight-line speed.',
            prosText: '+6 Top Speed, +4 DRS Overtaking Punch',
            consText: '-3 High-Speed Downforce stability in sweeping bends',
            statDeltas: {
              'topSpeed': 6,
              'drsEfficiency': 4,
              'highSpeedDownforce': -3,
            },
            baseCostMillions: 6,
            baseRacesToDeliver: 1,
          ),
          RdSpecPhilosophy(
            id: 'rw_monaco_barn_door',
            name: 'Maximum Downforce Dual Element',
            description: 'Steep angle of attack rear wing producing immense rear grip through fast corners.',
            prosText: '+5 High-Speed Downforce, +3 Medium-Speed Downforce',
            consText: '-4 Top Speed penalty on long straights',
            statDeltas: {
              'highSpeedDownforce': 5,
              'mediumSpeedDownforce': 3,
              'topSpeed': -4,
            },
            baseCostMillions: 7,
            baseRacesToDeliver: 1,
          ),
        ];

      case CarPartType.underfloor:
        return const [
          RdSpecPhilosophy(
            id: 'uf_venturi_expansion',
            name: 'Deep Venturi Tunnel Tunnels',
            description: 'Radical floor fences and throat expansion for pure ground effect suction without drag.',
            prosText: '+5 High-Speed Downforce, +4 Medium-Speed Downforce, +2 Top Speed',
            consText: '-3 Tyre Preservation if porpoising occurs on bumpy surfaces',
            statDeltas: {
              'highSpeedDownforce': 5,
              'mediumSpeedDownforce': 4,
              'topSpeed': 2,
              'tyrePreservation': -3,
            },
            baseCostMillions: 12,
            baseRacesToDeliver: 2,
          ),
          RdSpecPhilosophy(
            id: 'uf_edge_vortex',
            name: 'Flexible Floor Edge Winglets',
            description: 'Seals the underfloor with high-energy vortices to prevent tyre wash contamination.',
            prosText: '+3 High-Speed Downforce, +3 Tyre Preservation',
            consText: 'Requires stringent structural stiffness testing',
            statDeltas: {
              'highSpeedDownforce': 3,
              'tyrePreservation': 3,
            },
            baseCostMillions: 9,
            baseRacesToDeliver: 1,
          ),
        ];

      case CarPartType.sidepodsCooling:
        return const [
          RdSpecPhilosophy(
            id: 'sp_shrinkwrap_aero',
            name: 'Extreme Undercut Shrinkwrap',
            description: 'Ultra-compact sidepod packaging maximizing airflow volume to the diffuser.',
            prosText: '+4 Medium-Speed Downforce, +3 Acceleration',
            consText: '-4 Reliability: Tighter engine heat tolerance, risk of overheating DNF',
            statDeltas: {
              'mediumSpeedDownforce': 4,
              'acceleration': 3,
              'reliability': -4,
            },
            baseCostMillions: 8,
            baseRacesToDeliver: 1,
          ),
          RdSpecPhilosophy(
            id: 'sp_enhanced_cooling',
            name: 'High-Efficiency Radiator Louvres',
            description: 'Expanded cooling ducts ensuring bulletproof engine reliability in hot weather.',
            prosText: '+7 Reliability endurance, prevents power degradation in dirty air',
            consText: '-2 Top Speed straight-line aerodynamic drag penalty',
            statDeltas: {
              'reliability': 7,
              'topSpeed': -2,
            },
            baseCostMillions: 5,
            baseRacesToDeliver: 1,
          ),
        ];

      case CarPartType.suspensionBrakes:
        return const [
          RdSpecPhilosophy(
            id: 'sb_tyre_whisperer',
            name: 'Anti-Dive Geometry & Soft Damper Rate',
            description: 'Gentle load transfer during braking and cornering to protect tire tread surfaces.',
            prosText: '+7 Tyre Preservation (reduces thermal blistering and cliff drop-off)',
            consText: '-2 Initial braking bite and rapid steering responsiveness',
            statDeltas: {
              'tyrePreservation': 7,
              'lowSpeedDownforce': -2,
            },
            baseCostMillions: 7,
            baseRacesToDeliver: 1,
          ),
          RdSpecPhilosophy(
            id: 'sb_carbon_ceramic',
            name: 'Carbon-Ceramic Calipers & Stiff Anti-Roll Bar',
            description: 'Ultra-late braking capabilities and rapid curb-riding directional changes.',
            prosText: '+4 Acceleration traction out of corners, +3 Low-Speed bite',
            consText: '-3 Tyre Preservation: Higher tyre stress under heavy trail-braking',
            statDeltas: {
              'acceleration': 4,
              'lowSpeedDownforce': 3,
              'tyrePreservation': -3,
            },
            baseCostMillions: 8,
            baseRacesToDeliver: 1,
          ),
        ];

      case CarPartType.powerUnit:
        return const [
          RdSpecPhilosophy(
            id: 'pu_qualifying_boost',
            name: 'Aggressive Turbo Boost & ERS Dump',
            description: 'Unlocks maximum combustion pressure and 160hp battery dump output.',
            prosText: '+6 Top Speed, +5 Acceleration off the line and DRS overtakes',
            consText: '-5 Reliability: High wear rate on Internal Combustion Engine pistons',
            statDeltas: {
              'topSpeed': 6,
              'acceleration': 5,
              'reliability': -5,
            },
            baseCostMillions: 14,
            baseRacesToDeliver: 2,
          ),
          RdSpecPhilosophy(
            id: 'pu_efficiency_master',
            name: 'MGU-H Heat Recovery Efficiency',
            description: 'Superior electrical regeneration providing consistent harvesting and longevity.',
            prosText: '+3 Acceleration, +5 Reliability, +3 Fuel Saving economy',
            consText: '+0 Peak Top Speed change',
            statDeltas: {
              'acceleration': 3,
              'reliability': 5,
            },
            baseCostMillions: 11,
            baseRacesToDeliver: 2,
          ),
        ];

      case CarPartType.pitEquipment:
        return const [
          RdSpecPhilosophy(
            id: 'pit_rapid_guns',
            name: 'Ultra-Torque Pneumatic Wheel Guns',
            description: 'High-RPM titanium wheel guns for sub-2.0 second pit stop releases.',
            prosText: 'Reduces pit stop duration by 0.4s to 0.7s on every stop',
            consText: 'Requires rigorous pit crew training to avoid cross-threading errors',
            statDeltas: {
              'acceleration': 1, // subtle crew cohesion boost
            },
            baseCostMillions: 4,
            baseRacesToDeliver: 1,
          ),
        ];
    }
  }
}

class RdProject {
  final String id;
  final CarPartType partType;
  final RdSpecPhilosophy specPhilosophy;
  final int racesRemaining;
  final bool isRushDevelopment;
  final bool isCompleted;
  final bool hadManufacturingDefect;
  final DateTime startedAt;

  const RdProject({
    required this.id,
    required this.partType,
    required this.specPhilosophy,
    required this.racesRemaining,
    this.isRushDevelopment = false,
    this.isCompleted = false,
    this.hadManufacturingDefect = false,
    required this.startedAt,
  });

  RdProject copyWith({
    int? racesRemaining,
    bool? isCompleted,
    bool? hadManufacturingDefect,
  }) {
    return RdProject(
      id: id,
      partType: partType,
      specPhilosophy: specPhilosophy,
      racesRemaining: racesRemaining ?? this.racesRemaining,
      isRushDevelopment: isRushDevelopment,
      isCompleted: isCompleted ?? this.isCompleted,
      hadManufacturingDefect: hadManufacturingDefect ?? this.hadManufacturingDefect,
      startedAt: startedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'partType': partType.index,
        'specId': specPhilosophy.id,
        'racesRemaining': racesRemaining,
        'isRushDevelopment': isRushDevelopment,
        'isCompleted': isCompleted,
        'hadManufacturingDefect': hadManufacturingDefect,
        'startedAt': startedAt.toIso8601String(),
      };
}
