import 'package:flutter/material.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';

class QuestListTile extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onComplete;
  final bool showDomain;

  const QuestListTile({
    required this.quest,
    this.onComplete,
    this.showDomain = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = BuildingConfig.colorForStat(quest.domain);
    final statLabel = OperatorCopy.shortStatLabel(quest.domain);
    final tierLabel = OperatorCopy.missionTier(quest.tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: OperatorGradients.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 5, color: color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MissionBadge(label: tierLabel, color: color),
                    const Spacer(),
                    Text(
                      '+${quest.xpValue} XP',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  quest.title,
                  style: const TextStyle(
                    color: OperatorPalette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showDomain
                      ? '$statLabel • ${OperatorCopy.statLabel(quest.domain)}'
                      : OperatorCopy.statLabel(quest.domain),
                  style: OperatorTextStyles.muted,
                ),
                if (onComplete != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Complete Mission'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MissionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
