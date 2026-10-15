class PressOption {
  final String text;
  final int driverMoraleDelta;
  final int teamEngineTrustDelta;
  final int sponsorConfidenceDelta;
  final String consequenceSummary;

  const PressOption({
    required this.text,
    this.driverMoraleDelta = 0,
    this.teamEngineTrustDelta = 0,
    this.sponsorConfidenceDelta = 0,
    required this.consequenceSummary,
  });
}

class PressQuestion {
  final String id;
  final String journalistName;
  final String mediaOutlet; // E.g., 'Sky Sports F1', 'Canal+', 'BBC Sport'
  final String questionText;
  final List<PressOption> options;

  const PressQuestion({
    required this.id,
    required this.journalistName,
    required this.mediaOutlet,
    required this.questionText,
    required this.options,
  });
}

class PaddockPoliticsEngine {
  static List<PressQuestion> generatePostRaceQuestions({
    required String teamName,
    required String driver1LastName,
    required int bestFinishPosition,
  }) {
    List<PressQuestion> questions = [];

    if (bestFinishPosition <= 3) {
      questions.add(PressQuestion(
        id: 'q_podium',
        journalistName: 'Martin Brundle',
        mediaOutlet: 'Sky Sports F1',
        questionText: 'A sensational podium result today for $teamName! Is this the turning point in your title campaign?',
        options: [
          const PressOption(
            text: 'Full credit to the drivers and the factory crew. We are just getting started!',
            driverMoraleDelta: 10,
            sponsorConfidenceDelta: 10,
            consequenceSummary: '+10 Driver Morale, +10 Sponsor Confidence',
          ),
          const PressOption(
            text: 'We got lucky with the Safety Car, but our base car pace still needs serious upgrades.',
            driverMoraleDelta: -2,
            teamEngineTrustDelta: 5,
            consequenceSummary: 'Factory engineers motivated to bring new parts.',
          ),
        ],
      ));
    } else {
      questions.add(PressQuestion(
        id: 'q_midfield',
        journalistName: 'Will Buxton',
        mediaOutlet: 'F1 TV',
        questionText: '$driver1LastName seemed frustrated with the car balance over team radio. What happened on the pit wall?',
        options: [
          PressOption(
            text: '$driver1LastName pushed to the absolute limit. We stand by our driver completely.',
            driverMoraleDelta: 8,
            sponsorConfidenceDelta: 2,
            consequenceSummary: '+8 Driver Morale, +2 Sponsor Trust',
          ),
          const PressOption(
            text: 'Our pit stop execution was sluggish today. We need to hold the pit crew accountable.',
            driverMoraleDelta: -4,
            sponsorConfidenceDelta: -4,
            consequenceSummary: 'Pit crew tension increases. Driver morale drops.',
          ),
        ],
      ));
    }

    questions.add(PressQuestion(
      id: 'q_future',
      journalistName: 'Rosanna Tennant',
      mediaOutlet: 'BBC Sport',
      questionText: 'With the FIA regulation overhaul coming next season, is $teamName shifting development resources early?',
      options: [
        const PressOption(
          text: 'We are focusing 100% on the next generation chassis to fight for the World Championship!',
          sponsorConfidenceDelta: 8,
          consequenceSummary: '+8 Sponsor Excitement for Next Season',
        ),
        const PressOption(
          text: 'We will fight for every single point this season before thinking about next year.',
          driverMoraleDelta: 5,
          consequenceSummary: '+5 Driver Morale',
        ),
      ],
    ));

    return questions;
  }
}

