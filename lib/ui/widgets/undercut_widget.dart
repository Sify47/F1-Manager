import 'package:flutter/material.dart';
import '../../engine/pit_wall_strategy.dart';
import '../theme/f1_theme.dart';

class UndercutWidget extends StatelessWidget {
  final UndercutPrediction? prediction;

  const UndercutWidget({super.key, this.prediction});

  @override
  Widget build(BuildContext context) {
    if (prediction == null) return const SizedBox.shrink();

    final bool ahead = prediction!.willExitAhead;
    final Color color = ahead ? F1Theme.drsGreen : Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark.withValues(alpha: 0.95),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(ahead ? Icons.trending_up : Icons.traffic, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'PIT EXIT PREDICTOR: ',
                      style: F1Theme.f1Display(fontSize: 9, color: Colors.grey),
                    ),
                    Text(
                      'PROJECTED P${prediction!.predictedExitPosition}',
                      style: F1Theme.f1Display(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
                Text(
                  prediction!.analysisText,
                  style: F1Theme.f1Body(fontSize: 9, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
