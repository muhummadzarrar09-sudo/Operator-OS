import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/sub_stats_config.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/widgets/quest_list_tile.dart';

class StatDetailScreen extends ConsumerStatefulWidget {
  final String statKey;

  const StatDetailScreen({required this.statKey, super.key});

  @override
  ConsumerState<StatDetailScreen> createState() => _StatDetailScreenState();
}

class _StatDetailScreenState extends ConsumerState<StatDetailScreen> {
  final _titleController = TextEditingController();
  QuestTier _selectedTier = QuestTier.standard;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statAsync = ref.watch(statByKeyStreamProvider(widget.statKey));
    final questsAsync = ref.watch(questsByDomainStreamProvider(widget.statKey));
    final userId = ref.watch(currentUserIdProvider);
    final color = BuildingConfig.colorForStat(widget.statKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.statKey.toUpperCase()),
        backgroundColor: color.withValues(alpha: 0.2),
      ),
      body: statAsync.when(
        data: (stat) {
          if (stat == null) {
            return const Center(child: Text('Stat not found.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(stat: stat, color: color),
                const SizedBox(height: 24),
                _RadarChart(statKey: widget.statKey, subStatsJson: stat.subStatsJson),
                const SizedBox(height: 24),
                _AddQuestForm(
                  titleController: _titleController,
                  selectedTier: _selectedTier,
                  onTierChanged: (t) => setState(() => _selectedTier = t),
                  onCreate: () => _createQuest(userId),
                  color: color,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pending Quests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                questsAsync.when(
                  data: (quests) {
                    if (quests.isEmpty) {
                      return const Text(
                        'No pending quests. Create one above!',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    return Column(
                      children: quests.map((q) => QuestListTile(
                        quest: q,
                        showDomain: false,
                        onComplete: userId == null
                            ? null
                            : () => ref.read(questsRepositoryProvider).completeQuest(userId, q.id),
                      )).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Quest error: $err'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Stat error: $err')),
      ),
    );
  }

  void _createQuest(String? userId) {
    final title = _titleController.text.trim();
    if (userId == null || title.isEmpty) return;
    ref.read(questsRepositoryProvider).createQuest(
      userId: userId,
      domain: widget.statKey,
      title: title,
      tier: _selectedTier,
    );
    _titleController.clear();
    setState(() => _selectedTier = QuestTier.standard);
  }
}

class _Header extends StatelessWidget {
  final Stat stat;
  final Color color;

  const _Header({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    final tier = XpConfig.tierForLevel(stat.level);
    final tierName = BuildingConfig.tierName(tier);
    final progress = _calculateProgress();
    final nextLevelXp = XpConfig.xpForLevel(stat.level + 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    'Lv ${stat.level} — $tierName',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${stat.currentXp} / $nextLevelXp XP',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress() {
    if (stat.level == 1) {
      return stat.currentXp / XpConfig.xpForLevel(2);
    }
    final base = XpConfig.xpForLevel(stat.level);
    final next = XpConfig.xpForLevel(stat.level + 1);
    return (stat.currentXp - base) / (next - base);
  }
}

class _RadarChart extends StatelessWidget {
  final String statKey;
  final String subStatsJson;

  const _RadarChart({required this.statKey, required this.subStatsJson});

  @override
  Widget build(BuildContext context) {
    final labels = SubStatsConfig.subStats[statKey] ?? [];
    if (labels.isEmpty) return const SizedBox.shrink();

    final values = SubStatsConfig.parseValues(subStatsJson);
    final entries = labels.map((label) {
      final value = (values[label] ?? 0).toDouble().clamp(0, 100).toDouble();
      return RadarEntry(value: value);
    }).toList();

    final color = BuildingConfig.colorForStat(statKey);

    return SizedBox(
      height: 260,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.circle,
          dataSets: [
            RadarDataSet(
              fillColor: color.withValues(alpha: 0.2),
              borderColor: color,
              dataEntries: entries,
              entryRadius: 4,
              borderWidth: 2,
            ),
          ],
          getTitle: (index, angle) => RadarChartTitle(
            text: labels[index].toUpperCase(),
            angle: angle,
          ),
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
          gridBorderData: const BorderSide(color: Colors.grey, width: 1),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _AddQuestForm extends StatelessWidget {
  final TextEditingController titleController;
  final QuestTier selectedTier;
  final ValueChanged<QuestTier> onTierChanged;
  final VoidCallback onCreate;
  final Color color;

  const _AddQuestForm({
    required this.titleController,
    required this.selectedTier,
    required this.onTierChanged,
    required this.onCreate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Quest',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<QuestTier>(
              initialValue: selectedTier,
              decoration: const InputDecoration(
                labelText: 'Tier',
                border: OutlineInputBorder(),
              ),
              items: QuestTier.values.map((tier) {
                return DropdownMenuItem(
                  value: tier,
                  child: Text('${tier.name} (${tier.xp} XP)'),
                );
              }).toList(),
              onChanged: (t) => onTierChanged(t!),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Create Quest'),
            ),
          ],
        ),
      ),
    );
  }
}
