class PressOption {
  final String text;
  final int driverMoraleDelta;
  final String? targetDriverId;
  final int teamEngineTrustDelta;
  final int boardConfidenceDelta;
  final int sponsorBonusMillions;
  final String consequenceSummary;

  const PressOption({
    required this.text,
    this.driverMoraleDelta = 0,
    this.targetDriverId,
    this.teamEngineTrustDelta = 0,
    this.boardConfidenceDelta = 0,
    this.sponsorBonusMillions = 0,
    required this.consequenceSummary,
  });
}

class PressQuestion {
  final String id;
  final String journalistName;
  final String mediaOutlet; // E.g., 'Sky Sports F1', 'Canal+', 'BBC Sport', 'F1 TV'
  final String topic; // E.g., 'PODIUM GLORY', 'CIVIL WAR', 'MECHANICAL DNF'
  final String questionText;
  final List<PressOption> options;

  const PressQuestion({
    required this.id,
    required this.journalistName,
    required this.mediaOutlet,
    required this.topic,
    required this.questionText,
    required this.options,
  });
}

class PaddockPoliticsEngine {
  static List<PressQuestion> generatePostRaceQuestions({
    required String teamName,
    required String driver1LastName,
    String? driver2LastName,
    String? driver1Id,
    String? driver2Id,
    required int bestFinishPosition,
    bool hadTeammateConflict = false,
    bool hadPitDelay = false,
    bool hadMechanicalDnf = false,
    bool achievedBoardObjectives = false,
  }) {
    final List<PressQuestion> questions = [];
    final d2Name = driver2LastName ?? 'Teammate';

    // 1. PRIMARY DRAMATIC STORYLINE QUESTION
    if (hadMechanicalDnf) {
      questions.add(PressQuestion(
        id: 'q_dnf_crisis',
        journalistName: 'Martin Brundle',
        mediaOutlet: 'Sky Sports F1',
        topic: 'MECHANICAL DNF CRISIS',
        questionText:
            'A crushing mechanical retirement for $driver1LastName today. Smoke poured from the car on lap. Is this an engine reliability crisis for $teamName?',
        options: [
          PressOption(
            text: 'We demand immediate explanations from our power unit engineers. This level of reliability is unacceptable.',
            driverMoraleDelta: 6,
            targetDriverId: driver1Id,
            teamEngineTrustDelta: -8,
            boardConfidenceDelta: -4,
            consequenceSummary: '+6 Driver Morale, -8 Factory Trust, -4% Board Confidence',
          ),
          PressOption(
            text: 'We win together and lose together. The engineering staff works round the clock, and we stand by them.',
            driverMoraleDelta: 4,
            teamEngineTrustDelta: 10,
            boardConfidenceDelta: 3,
            consequenceSummary: '+4 Driver Morale, +10 Factory Trust, +3% Board Confidence',
          ),
          PressOption(
            text: 'Telemetry shows the driver abused the kerbs and pushed past hardware tolerance limits.',
            driverMoraleDelta: -12,
            targetDriverId: driver1Id,
            boardConfidenceDelta: -5,
            consequenceSummary: '-12 Driver Morale, -5% Board Confidence (Driver furious)',
          ),
        ],
      ));
    } else if (hadTeammateConflict) {
      questions.add(PressQuestion(
        id: 'q_teammate_war',
        journalistName: 'Will Buxton',
        mediaOutlet: 'F1 TV',
        topic: 'TEAM ORDERS CIVIL WAR',
        questionText:
            'Heated radio friction erupted when team orders were called between $driver1LastName and $d2Name. How do you prevent civil war inside the garage?',
        options: [
          PressOption(
            text: 'The team always comes first. Our drivers are contracted to win championships for $teamName, not themselves.',
            driverMoraleDelta: -5,
            boardConfidenceDelta: 6,
            teamEngineTrustDelta: 4,
            consequenceSummary: '+6% Board Confidence, -5 Driver Morale (Strict Discipline)',
          ),
          PressOption(
            text: 'They are gladiators fighting for millimetres. We let them race freely, and the fans loved the spectacle!',
            driverMoraleDelta: 10,
            boardConfidenceDelta: -3,
            sponsorBonusMillions: 1,
            consequenceSummary: '+10 Driver Morale, +\$1.0M Viral Media Sponsor Bounty, -3% Board Confidence',
          ),
          PressOption(
            text: 'The pit wall delayed our strategic communication. The fault is mine as Team Principal, not the drivers.',
            driverMoraleDelta: 8,
            boardConfidenceDelta: 4,
            consequenceSummary: '+8 Driver Morale, +4% Board Confidence (Humble Leadership)',
          ),
        ],
      ));
    } else if (bestFinishPosition == 1) {
      questions.add(PressQuestion(
        id: 'q_win_glory',
        journalistName: 'David Croft',
        mediaOutlet: 'Sky Sports F1',
        topic: 'GRAND PRIX VICTORY',
        questionText:
            'WHAT A RACE! $teamName takes the checkered flag in dominant fashion! Is this the definitive turning point in your title charge?',
        options: [
          PressOption(
            text: 'Sensational drive! The factory, pit wall, and drivers executed perfection. This is our championship year!',
            driverMoraleDelta: 15,
            boardConfidenceDelta: 12,
            sponsorBonusMillions: 2,
            consequenceSummary: '+15 Driver Morale, +12% Board Confidence, +\$2.0M Sponsor Win Bounty',
          ),
          PressOption(
            text: 'A brilliant victory, but we remain humble. Red Bull and Ferrari will hit back hard next race.',
            driverMoraleDelta: 8,
            boardConfidenceDelta: 8,
            teamEngineTrustDelta: 8,
            sponsorBonusMillions: 1,
            consequenceSummary: '+8 Driver Morale, +8% Board Confidence, +\$1.0M Sponsor Bonus',
          ),
        ],
      ));
    } else if (bestFinishPosition <= 3) {
      questions.add(PressQuestion(
        id: 'q_podium',
        journalistName: 'Martin Brundle',
        mediaOutlet: 'Sky Sports F1',
        topic: 'PODIUM BREAKTHROUGH',
        questionText:
            'A sensational podium finish today for $teamName! Are your latest factory aero upgrades outperforming expectations?',
        options: [
          PressOption(
            text: 'Full credit to the drivers and the factory crew. Our aero correlations are finally translating to real lap time!',
            driverMoraleDelta: 10,
            boardConfidenceDelta: 8,
            teamEngineTrustDelta: 8,
            sponsorBonusMillions: 1,
            consequenceSummary: '+10 Driver Morale, +8% Board Confidence, +\$1.0M Sponsor Bonus',
          ),
          PressOption(
            text: 'We seized the opportunities and made bold pit calls, but our baseline downforce still needs serious work.',
            driverMoraleDelta: 2,
            teamEngineTrustDelta: 6,
            boardConfidenceDelta: 4,
            consequenceSummary: '+4% Board Confidence, +6 Factory Motivation, +2 Morale',
          ),
        ],
      ));
    } else if (hadPitDelay) {
      questions.add(PressQuestion(
        id: 'q_pit_blunder',
        journalistName: 'Lawrence Barretto',
        mediaOutlet: 'F1.com',
        topic: 'PIT CREW BOTCHED STOP',
        questionText:
            'A sluggish pit stop cost $teamName critical track position and points. Will you be implementing crew reshuffles back at base?',
        options: [
          PressOption(
            text: 'Our crew operates under unbelievable pressure. They have saved us many times, and I back them completely.',
            driverMoraleDelta: 4,
            teamEngineTrustDelta: 8,
            boardConfidenceDelta: 2,
            consequenceSummary: '+8 Factory Loyalty, +4 Driver Morale, +2% Board Confidence',
          ),
          PressOption(
            text: 'In modern Formula 1, four seconds lost in the box is unforgivable. We will be holding intensive drills this week.',
            driverMoraleDelta: -4,
            teamEngineTrustDelta: -6,
            boardConfidenceDelta: 4,
            consequenceSummary: '+4% Board Confidence, -6 Factory Trust, -4 Driver Morale',
          ),
        ],
      ));
    } else {
      questions.add(PressQuestion(
        id: 'q_midfield',
        journalistName: 'Will Buxton',
        mediaOutlet: 'F1 TV',
        topic: 'MIDFIELD SQUEEZE',
        questionText:
            '$driver1LastName seemed visibly frustrated with the car balance over team radio today. How do you respond to paddock whispers?',
        options: [
          PressOption(
            text: '$driver1LastName pushed to the absolute ragged edge. We stand by our driver and are committed to fixing the balance.',
            driverMoraleDelta: 8,
            targetDriverId: driver1Id,
            boardConfidenceDelta: 3,
            consequenceSummary: '+8 Driver Morale, +3% Board Confidence',
          ),
          PressOption(
            text: 'The car telemetry shows the package had more pace than what was delivered on track today.',
            driverMoraleDelta: -8,
            targetDriverId: driver1Id,
            boardConfidenceDelta: 2,
            consequenceSummary: '-8 Driver Morale, +2% Board Confidence (Driver disappointed)',
          ),
          PressOption(
            text: 'Our primary objective was gathering aerodynamic data for our upcoming floor revision.',
            teamEngineTrustDelta: 6,
            boardConfidenceDelta: 2,
            consequenceSummary: '+6 Factory Development Trust, +2% Board Confidence',
          ),
        ],
      ));
    }

    // 2. SECONDARY STRATEGIC & BOARD / SPONSOR QUESTION
    if (achievedBoardObjectives) {
      questions.add(PressQuestion(
        id: 'q_sponsor_celebration',
        journalistName: 'Rosanna Tennant',
        mediaOutlet: 'BBC Sport',
        topic: 'BOARD & SPONSOR TARGETS',
        questionText:
            'Your executive board and global sponsors confirmed that all weekend targets were met. How will this bolster your development budget?',
        options: [
          PressOption(
            text: 'These sponsor bounties will immediately fund our rush aerodynamic CFD development for the next Grand Prix.',
            boardConfidenceDelta: 8,
            teamEngineTrustDelta: 6,
            sponsorBonusMillions: 1,
            consequenceSummary: '+8% Board Confidence, +6 Factory Trust, +\$1.0M Sponsor Bounty',
          ),
          PressOption(
            text: 'Our priority is driver stability. Rewarding our drivers and crew ensures championship-level longevity.',
            driverMoraleDelta: 8,
            boardConfidenceDelta: 6,
            sponsorBonusMillions: 1,
            consequenceSummary: '+8 Driver Morale, +6% Board Confidence, +\$1.0M Sponsor Bounty',
          ),
        ],
      ));
    } else {
      questions.add(PressQuestion(
        id: 'q_regulations',
        journalistName: 'Rosanna Tennant',
        mediaOutlet: 'BBC Sport',
        topic: 'RESOURCE ALLOCATION & FUTURE',
        questionText:
            'With the FIA budget cap squeezing team expenditure, will $teamName shift development focus early toward next season’s chassis?',
        options: [
          PressOption(
            text: 'We will fight for every single championship point this season until the checkered flag in Abu Dhabi.',
            driverMoraleDelta: 6,
            boardConfidenceDelta: 4,
            consequenceSummary: '+6 Driver Morale, +4% Board Confidence',
          ),
          PressOption(
            text: 'We are prudently shifting our wind tunnel hours early to next year’s radical chassis concept.',
            boardConfidenceDelta: 6,
            driverMoraleDelta: -4,
            teamEngineTrustDelta: 6,
            consequenceSummary: '+6% Board Confidence, +6 Factory Trust, -4 Driver Morale',
          ),
        ],
      ));
    }

    return questions;
  }
}


