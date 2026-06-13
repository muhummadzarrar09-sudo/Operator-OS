import 'package:flutter/material.dart';
import 'package:operator_os/core/building_config.dart';
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

    return Card(
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(quest.title),
        subtitle: Text(
          '${showDomain ? "${quest.domain.toUpperCase()} • " : ""}'
          '${quest.tier.toUpperCase()} • ${quest.xpValue} XP',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: onComplete != null
            ? ElevatedButton(
                onPressed: onComplete,
                child: const Text('Done'),
              )
            : null,
      ),
    );
  }
}
