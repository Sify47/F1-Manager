import '../models/circuit.dart';

class CircuitsData {
  static const List<Circuit> allCircuits = [
    // 1. BAHRAIN
    Circuit(
      id: 'bahrain',
      name: 'Bahrain International Circuit',
      grandPrixName: 'Gulf Air Bahrain Grand Prix',
      country: 'Bahrain',
      flagEmoji: '🇧🇭',
      city: 'Sakhir',
      lengthKm: 5.412,
      totalLaps: 57,
      baseLapRecordSeconds: 91.447, // 1:31.447
      asphaltAbrasiveness: 0.88,    // High abrasiveness (rear tire punishment)
      overtakingDifficulty: 0.35,   // Good overtaking down T1 and T4
      pitLaneLossSeconds: 22.5,
      baseRainProbability: 0.02,
      baseTrackTemperature: 32.0,
      drsZonesCount: 3,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 1.8,
          baseBenchmarkSeconds: 29.5,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'Turn 1', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 2, name: 'Turn 2', type: CornerSpeedType.medium, lengthKm: 0.15),
            TrackCorner(cornerNumber: 3, name: 'Turn 3', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 0.6),
            TrackCorner(cornerNumber: 4, name: 'Turn 4', type: CornerSpeedType.medium, lengthKm: 0.2),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 2.1,
          baseBenchmarkSeconds: 39.8,
          corners: [
            TrackCorner(cornerNumber: 5, name: 'Turn 5', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 6, name: 'Turn 6', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 7, name: 'Turn 7', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 8, name: 'Turn 8', type: CornerSpeedType.slow, lengthKm: 0.15),
            TrackCorner(cornerNumber: 9, name: 'Turn 9/10 Hairpin', type: CornerSpeedType.slow, lengthKm: 0.25),
            TrackCorner(cornerNumber: 11, name: 'Turn 11', type: CornerSpeedType.medium, lengthKm: 0.3),
            TrackCorner(cornerNumber: 12, name: 'Turn 12', type: CornerSpeedType.fast, lengthKm: 0.3),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 1.512,
          baseBenchmarkSeconds: 22.1,
          corners: [
            TrackCorner(cornerNumber: 13, name: 'Turn 13', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 14, name: 'Turn 14/15', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 16, name: 'Main Straight', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 1.0),
          ],
        ),
      ],
    ),

    // 2. MONACO
    Circuit(
      id: 'monaco',
      name: 'Circuit de Monaco',
      grandPrixName: 'Grand Prix de Monaco',
      country: 'Monaco',
      flagEmoji: '🇲🇨',
      city: 'Monte Carlo',
      lengthKm: 3.337,
      totalLaps: 78,
      baseLapRecordSeconds: 72.909, // 1:12.909
      asphaltAbrasiveness: 0.15,    // Very smooth street tarmac, lowest tire wear
      overtakingDifficulty: 0.98,   // Almost impossible to overtake on track
      pitLaneLossSeconds: 19.8,
      baseRainProbability: 0.18,
      baseTrackTemperature: 28.0,
      drsZonesCount: 1,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 1.1,
          baseBenchmarkSeconds: 19.5,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'Sainte Dévote', type: CornerSpeedType.slow, lengthKm: 0.15),
            TrackCorner(cornerNumber: 2, name: 'Beau Rivage', type: CornerSpeedType.straight, lengthKm: 0.4),
            TrackCorner(cornerNumber: 3, name: 'Massenet', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 4, name: 'Casino Square', type: CornerSpeedType.medium, lengthKm: 0.2),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 1.25,
          baseBenchmarkSeconds: 34.2,
          corners: [
            TrackCorner(cornerNumber: 5, name: 'Mirabeau Haute', type: CornerSpeedType.slow, lengthKm: 0.1),
            TrackCorner(cornerNumber: 6, name: 'Grand Hotel Hairpin', type: CornerSpeedType.slow, lengthKm: 0.1), // Slowest corner in F1 (45 km/h)
            TrackCorner(cornerNumber: 7, name: 'Mirabeau Bas', type: CornerSpeedType.slow, lengthKm: 0.1),
            TrackCorner(cornerNumber: 8, name: 'Portier', type: CornerSpeedType.slow, lengthKm: 0.1),
            TrackCorner(cornerNumber: 9, name: 'Tunnel', type: CornerSpeedType.straight, lengthKm: 0.4),
            TrackCorner(cornerNumber: 10, name: 'Nouvelle Chicane', type: CornerSpeedType.slow, lengthKm: 0.15),
            TrackCorner(cornerNumber: 11, name: 'Tabac', type: CornerSpeedType.medium, lengthKm: 0.15),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 0.987,
          baseBenchmarkSeconds: 19.2,
          corners: [
            TrackCorner(cornerNumber: 12, name: 'Louis Chiron', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 13, name: 'Piscine Swimming Pool', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 14, name: 'La Rascasse', type: CornerSpeedType.slow, lengthKm: 0.15),
            TrackCorner(cornerNumber: 15, name: 'Anthony Noghès', type: CornerSpeedType.slow, lengthKm: 0.15),
          ],
        ),
      ],
    ),

    // 3. SILVERSTONE
    Circuit(
      id: 'silverstone',
      name: 'Silverstone Circuit',
      grandPrixName: 'British Grand Prix',
      country: 'United Kingdom',
      flagEmoji: '🇬🇧',
      city: 'Silverstone',
      lengthKm: 5.891,
      totalLaps: 52,
      baseLapRecordSeconds: 87.097, // 1:27.097
      asphaltAbrasiveness: 0.85,    // Brutal high-G lateral tire load (Maggotts/Becketts/Copse)
      overtakingDifficulty: 0.45,   // Good overtaking down Wellington & Hangar straights
      pitLaneLossSeconds: 20.2,
      baseRainProbability: 0.38,    // High rain probability
      baseTrackTemperature: 24.0,
      drsZonesCount: 2,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 2.0,
          baseBenchmarkSeconds: 27.8,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'Abbey', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 2, name: 'Farm', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 3, name: 'Village', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 4, name: 'The Loop', type: CornerSpeedType.slow, lengthKm: 0.15),
            TrackCorner(cornerNumber: 5, name: 'Aintree', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 6, name: 'Wellington Straight', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 0.8),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 2.1,
          baseBenchmarkSeconds: 35.4,
          corners: [
            TrackCorner(cornerNumber: 7, name: 'Brooklands', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 8, name: 'Luffield', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 9, name: 'Woodcote', type: CornerSpeedType.fast, lengthKm: 0.2),
            TrackCorner(cornerNumber: 10, name: 'Copse', type: CornerSpeedType.fast, lengthKm: 0.3), // 290 km/h flat out
            TrackCorner(cornerNumber: 11, name: 'Maggotts & Becketts', type: CornerSpeedType.fast, lengthKm: 0.6),
            TrackCorner(cornerNumber: 12, name: 'Chapel', type: CornerSpeedType.fast, lengthKm: 0.2),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 1.791,
          baseBenchmarkSeconds: 23.8,
          corners: [
            TrackCorner(cornerNumber: 13, name: 'Hangar Straight', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 0.9),
            TrackCorner(cornerNumber: 14, name: 'Stowe', type: CornerSpeedType.fast, lengthKm: 0.3),
            TrackCorner(cornerNumber: 15, name: 'Vale Chicane', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 16, name: 'Club', type: CornerSpeedType.medium, lengthKm: 0.2),
          ],
        ),
      ],
    ),

    // 4. SPA-FRANCORCHAMPS
    Circuit(
      id: 'spa',
      name: 'Circuit de Spa-Francorchamps',
      grandPrixName: 'Belgian Grand Prix',
      country: 'Belgium',
      flagEmoji: '🇧🇪',
      city: 'Stavelot',
      lengthKm: 7.004,
      totalLaps: 44,
      baseLapRecordSeconds: 106.276, // 1:46.276
      asphaltAbrasiveness: 0.72,
      overtakingDifficulty: 0.28,    // High overtaking down Kemmel Straight
      pitLaneLossSeconds: 22.0,
      baseRainProbability: 0.52,    // Legendary micro-climate Spa rain
      baseTrackTemperature: 21.0,
      drsZonesCount: 2,
      isSprintWeekend: true,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 2.3,
          baseBenchmarkSeconds: 30.5,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'La Source', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 2, name: 'Eau Rouge & Raidillon', type: CornerSpeedType.fast, lengthKm: 0.5), // High vertical G
            TrackCorner(cornerNumber: 3, name: 'Kemmel Straight', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 1.2),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 2.9,
          baseBenchmarkSeconds: 46.2,
          corners: [
            TrackCorner(cornerNumber: 4, name: 'Les Combes', type: CornerSpeedType.medium, lengthKm: 0.3),
            TrackCorner(cornerNumber: 5, name: 'Malmedy', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 6, name: 'Rivage', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 7, name: 'Bruxelles Hairpin', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 8, name: 'Pouhon', type: CornerSpeedType.fast, lengthKm: 0.4), // 260 km/h double apex
            TrackCorner(cornerNumber: 9, name: 'Campus', type: CornerSpeedType.medium, lengthKm: 0.3),
            TrackCorner(cornerNumber: 10, name: 'Stavelot', type: CornerSpeedType.medium, lengthKm: 0.3),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 1.804,
          baseBenchmarkSeconds: 29.5,
          corners: [
            TrackCorner(cornerNumber: 11, name: 'Blanchimont', type: CornerSpeedType.fast, lengthKm: 0.5), // 300+ km/h flat out
            TrackCorner(cornerNumber: 12, name: 'Bus Stop Chicane', type: CornerSpeedType.slow, lengthKm: 0.3),
          ],
        ),
      ],
    ),

    // 5. MONZA
    Circuit(
      id: 'monza',
      name: 'Autodromo Nazionale Monza',
      grandPrixName: 'Gran Premio d\'Italia',
      country: 'Italy',
      flagEmoji: '🇮🇹',
      city: 'Monza',
      lengthKm: 5.793,
      totalLaps: 53,
      baseLapRecordSeconds: 81.046, // 1:21.046 (Temple of Speed)
      asphaltAbrasiveness: 0.60,
      overtakingDifficulty: 0.22,    // Temple of slipstream & heavy braking
      pitLaneLossSeconds: 24.5,
      baseRainProbability: 0.15,
      baseTrackTemperature: 33.0,
      drsZonesCount: 2,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 1.9,
          baseBenchmarkSeconds: 26.8,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'Variante del Rettifilo (T1/T2)', type: CornerSpeedType.slow, lengthKm: 0.3),
            TrackCorner(cornerNumber: 2, name: 'Curva Grande', type: CornerSpeedType.fast, lengthKm: 0.5),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 2.1,
          baseBenchmarkSeconds: 27.4,
          corners: [
            TrackCorner(cornerNumber: 3, name: 'Variante della Roggia (T4/T5)', type: CornerSpeedType.slow, lengthKm: 0.3),
            TrackCorner(cornerNumber: 4, name: 'Curva di Lesmo 1', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 5, name: 'Curva di Lesmo 2', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 6, name: 'Curva del Serraglio', type: CornerSpeedType.straight, lengthKm: 0.6),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 1.793,
          baseBenchmarkSeconds: 26.8,
          corners: [
            TrackCorner(cornerNumber: 7, name: 'Variante Ascari', type: CornerSpeedType.fast, lengthKm: 0.4),
            TrackCorner(cornerNumber: 8, name: 'Curva Parabolica (Alboreto)', type: CornerSpeedType.fast, lengthKm: 0.4),
            TrackCorner(cornerNumber: 9, name: 'Pit Straight', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 0.9),
          ],
        ),
      ],
    ),

    // 6. SUZUKA
    Circuit(
      id: 'suzuka',
      name: 'Suzuka International Racing Course',
      grandPrixName: 'Japanese Grand Prix',
      country: 'Japan',
      flagEmoji: '🇯🇵',
      city: 'Suzuka',
      lengthKm: 5.807,
      totalLaps: 53,
      baseLapRecordSeconds: 90.983, // 1:30.983
      asphaltAbrasiveness: 0.86,
      overtakingDifficulty: 0.62,
      pitLaneLossSeconds: 21.0,
      baseRainProbability: 0.32,
      baseTrackTemperature: 25.0,
      drsZonesCount: 1,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 1.9,
          baseBenchmarkSeconds: 31.2,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'Turn 1 & 2', type: CornerSpeedType.fast, lengthKm: 0.3),
            TrackCorner(cornerNumber: 2, name: 'S-Curves (Snake)', type: CornerSpeedType.fast, lengthKm: 0.6),
            TrackCorner(cornerNumber: 3, name: 'Dunlop Curve', type: CornerSpeedType.fast, lengthKm: 0.3),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 2.2,
          baseBenchmarkSeconds: 39.5,
          corners: [
            TrackCorner(cornerNumber: 4, name: 'Degner 1 & 2', type: CornerSpeedType.medium, lengthKm: 0.3),
            TrackCorner(cornerNumber: 5, name: 'Hairpin (Turn 11)', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 6, name: 'Turn 12', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 7, name: 'Spoon Curve', type: CornerSpeedType.medium, lengthKm: 0.4),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 1.707,
          baseBenchmarkSeconds: 20.2,
          corners: [
            TrackCorner(cornerNumber: 8, name: 'Back Straight', type: CornerSpeedType.straight, lengthKm: 0.8),
            TrackCorner(cornerNumber: 9, name: '130R', type: CornerSpeedType.fast, lengthKm: 0.3), // 305 km/h high G
            TrackCorner(cornerNumber: 10, name: 'Casio Triangle Chicane', type: CornerSpeedType.slow, lengthKm: 0.2),
          ],
        ),
      ],
    ),

    // 7. INTERLAGOS
    Circuit(
      id: 'interlagos',
      name: 'Autódromo José Carlos Pace',
      grandPrixName: 'Grande Prêmio de São Paulo',
      country: 'Brazil',
      flagEmoji: '🇧🇷',
      city: 'São Paulo',
      lengthKm: 4.309,
      totalLaps: 71,
      baseLapRecordSeconds: 70.540, // 1:10.540
      asphaltAbrasiveness: 0.70,
      overtakingDifficulty: 0.38,
      pitLaneLossSeconds: 21.8,
      baseRainProbability: 0.45,    // Frequent rain storms & Safety Cars
      baseTrackTemperature: 28.0,
      drsZonesCount: 2,
      isSprintWeekend: true,
      sectors: [
        TrackSector(
          sectorNumber: 1,
          lengthKm: 1.4,
          baseBenchmarkSeconds: 18.5,
          corners: [
            TrackCorner(cornerNumber: 1, name: 'Senna S (T1/T2)', type: CornerSpeedType.slow, lengthKm: 0.3),
            TrackCorner(cornerNumber: 2, name: 'Curva do Sol', type: CornerSpeedType.medium, lengthKm: 0.2),
            TrackCorner(cornerNumber: 3, name: 'Reta Oposta', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 0.7),
          ],
        ),
        TrackSector(
          sectorNumber: 2,
          lengthKm: 1.8,
          baseBenchmarkSeconds: 35.8,
          corners: [
            TrackCorner(cornerNumber: 4, name: 'Descida do Lago', type: CornerSpeedType.medium, lengthKm: 0.3),
            TrackCorner(cornerNumber: 5, name: 'Ferradura', type: CornerSpeedType.medium, lengthKm: 0.3),
            TrackCorner(cornerNumber: 6, name: 'Bico de Pato Hairpin', type: CornerSpeedType.slow, lengthKm: 0.2),
            TrackCorner(cornerNumber: 7, name: 'Mergulho', type: CornerSpeedType.fast, lengthKm: 0.3),
            TrackCorner(cornerNumber: 8, name: 'Junção', type: CornerSpeedType.slow, lengthKm: 0.2),
          ],
        ),
        TrackSector(
          sectorNumber: 3,
          lengthKm: 1.109,
          baseBenchmarkSeconds: 16.2,
          corners: [
            TrackCorner(cornerNumber: 9, name: 'Subida dos Boxes', type: CornerSpeedType.fast, lengthKm: 0.4),
            TrackCorner(cornerNumber: 10, name: 'Main Straight', type: CornerSpeedType.straight, isDrsZone: true, lengthKm: 0.6),
          ],
        ),
      ],
    ),
  ];

  static Circuit? getCircuitById(String id) {
    try {
      return allCircuits.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

