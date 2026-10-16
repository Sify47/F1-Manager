import 'package:flutter/material.dart';
import '../../models/board_objective.dart';
import '../../state/career_controller.dart';
import '../theme/f1_theme.dart';

class BoardObjectivesCard extends StatelessWidget {
  final CareerController career;

  const BoardObjectivesCard({super.key, required this.career});

  @override
  Widget build(BuildContext context) {
    final confidence = career.boardConfidence;
    final rating = career.boardConfidenceRating;
    final objectives = career.currentObjectives;

    Color confidenceColor;
    if (confidence >= 80) {
      confidenceColor = Colors.greenAccent;
    } else if (confidence >= 65) {
      confidenceColor = Colors.amberAccent;
    } else if (confidence >= 45) {
      confidenceColor = Colors.orangeAccent;
    } else {
      confidenceColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Board Room Title & Confidence Indicator
          Row(
            children: [
              const Icon(Icons.corporate_fare, color: F1Theme.f1Red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOARD ROOM & SPONSOR CHALLENGES',
                      style: F1Theme.f1Display(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Grand Prix Missions & Executive Confidence',
                      style: F1Theme.f1Body(fontSize: 9, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              // Board Confidence Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: confidenceColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      confidence >= 65 ? Icons.sentiment_very_satisfied : Icons.warning_amber,
                      color: confidenceColor,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$confidence% $rating'.toUpperCase(),
                      style: F1Theme.f1Display(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: confidenceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Objectives Cards
          ...objectives.map((obj) => _buildObjectiveItem(obj)),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(BoardObjective obj) {
    Color categoryColor;
    String categoryLabel;
    IconData categoryIcon;

    switch (obj.category) {
      case ObjectiveCategory.boardExpectation:
        categoryColor = Colors.redAccent;
        categoryLabel = 'BOARD EXPECTATION';
        categoryIcon = Icons.stars;
        break;
      case ObjectiveCategory.sponsorBounty:
        categoryColor = Colors.greenAccent;
        categoryLabel = 'SPONSOR BOUNTY';
        categoryIcon = Icons.monetization_on;
        break;
      case ObjectiveCategory.rivalryShootout:
        categoryColor = Colors.amberAccent;
        categoryLabel = 'RIVAL SHOOTOUT';
        categoryIcon = Icons.sports_mma;
        break;
      case ObjectiveCategory.tacticalMastery:
        categoryColor = Colors.lightBlueAccent;
        categoryLabel = 'TACTICAL MASTERCLASS';
        categoryIcon = Icons.psychology;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: F1Theme.carbonBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: F1Theme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon, size: 9, color: categoryColor),
                    const SizedBox(width: 4),
                    Text(
                      categoryLabel,
                      style: F1Theme.f1Display(fontSize: 8, color: categoryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Status / Reward Chip
              if (obj.isEvaluated) ...[
                if (obj.isAchieved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Text(
                      'ACHIEVED ✅ (+\$${obj.rewardMillions}M)',
                      style: F1Theme.f1Display(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(
                      'MISSED ❌ (-${obj.confidencePenalty}%)',
                      style: F1Theme.f1Display(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
              ] else ...[
                Text(
                  '+\$${obj.rewardMillions}M • +${obj.confidenceBonus}%',
                  style: F1Theme.f1Mono(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            obj.title,
            style: F1Theme.f1Display(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            obj.description,
            style: F1Theme.f1Body(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

