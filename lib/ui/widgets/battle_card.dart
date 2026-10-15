import 'package:flutter/material.dart';
import '../../models/race_event.dart';
import '../theme/f1_theme.dart';

class BattleCardWidget extends StatelessWidget {
  final BattleActionCard? battle;
  final RaceEvent? latestIncident;

  const BattleCardWidget({super.key, this.battle, this.latestIncident});

  @override
  Widget build(BuildContext context) {
    if (battle == null && latestIncident == null) return const SizedBox.shrink();

    final bool isIncident = latestIncident != null &&
        (latestIncident!.severity == EventSeverity.warning || latestIncident!.severity == EventSeverity.critical);

    final title = isIncident ? latestIncident!.title : (battle?.headline ?? '');
    final description = isIncident ? latestIncident!.description : (battle?.detail ?? '');
    final color = isIncident
        ? (latestIncident!.severity == EventSeverity.critical ? F1Theme.f1Red : Colors.amber)
        : F1Theme.drsGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: F1Theme.surfaceDark.withValues(alpha: 0.95),
        border: Border(
          left: BorderSide(color: color, width: 4),
          bottom: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIncident ? Icons.warning_amber_rounded : Icons.flash_on,
                  color: color,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: F1Theme.f1Display(fontSize: 9, color: color, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: F1Theme.f1Body(fontSize: 10, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
