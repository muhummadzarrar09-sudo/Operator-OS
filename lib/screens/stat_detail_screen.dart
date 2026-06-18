import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/core/sub_stats_config.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/services/memory_archive_refresh.dart';
import 'package:operator_os/widgets/mission_complete_ceremony.dart';
import 'package:operator_os/widgets/operator_card.dart';
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
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: Text('${OperatorCopy.shortStatLabel(widget.statKey)} Command'),
        backgroundColor: color.withValues(alpha: 0.16),
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
                const SizedBox(height: 18),
                _RadarPanel(statKey: widget.statKey, subStatsJson: stat.subStatsJson),
                const SizedBox(height: 18),
                _AddQuestForm(
                  statKey: widget.statKey,
                  titleController: _titleController,
                  selectedTier: _selectedTier,
                  onTierChanged: (t) => setState(() => _selectedTier = t),
                  onCreate: () => _createQuest(userId),
                  color: color,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text('MISSION BOARD', style: OperatorTextStyles.overline),
                    const Spacer(),
                    questsAsync.maybeWhen(
                      data: (quests) => Text('${quests.length} pending', style: OperatorTextStyles.muted),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                questsAsync.when(
                  data: (quests) {
                    if (quests.isEmpty) {
                      return OperatorCard(
                        label: 'NO MISSIONS',
                        title: '${OperatorCopy.statLabel(widget.statKey)} is waiting.',
                        body: 'Forge one focused mission above to grow this building.',
                        icon: Icons.assignment_outlined,
                        accentColor: color,
                      );
                    }
                    return Column(
                      children: quests.map((q) => QuestListTile(
                        quest: q,
                        showDomain: false,
                        onComplete: userId == null
                            ? null
                            : () async {
                                await ref.read(questsRepositoryProvider).completeQuest(userId, q.id);
                                await refreshMemoryArchive(ref);
                                if (!context.mounted) return;
                                await showMissionCompleteCeremony(
                                  context: context,
                                  statKey: q.domain,
                                  xp: q.xpValue,
                                );
                              },
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: OperatorPalette.panelRaised,
        content: Text('Mission forged for ${OperatorCopy.statLabel(widget.statKey)}.'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Stat stat;
  final Color color;

  const _Header({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    final tier = XpConfig.tierForLevel(stat.level);
    final tierName = OperatorCopy.tierName(tier);
    final progress = _calculateProgress();
    final nextLevelXp = XpConfig.xpForLevel(stat.level + 1);
    final xpRemaining = math.max(0, nextLevelXp - stat.currentXp);

    return OperatorCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 108,
                width: 108,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 24),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/compound/${stat.statKey}_t$tier.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.home_work_outlined, color: color, size: 52),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat.statKey.toUpperCase(), style: OperatorTextStyles.overline),
                    const SizedBox(height: 5),
                    Text(OperatorCopy.statLabel(stat.statKey), style: OperatorTextStyles.title),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(label: 'Level ${stat.level}', color: color),
                        _Pill(label: 'Tier $tier • $tierName', color: OperatorPalette.parchmentGold),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${stat.currentXp} XP earned • $xpRemaining XP to next level', style: OperatorTextStyles.body),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: OperatorPalette.borderDim,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(OperatorCopy.buildingLine(stat.statKey), style: OperatorTextStyles.muted),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (stat.level == 1) {
      return (stat.currentXp / XpConfig.xpForLevel(2)).clamp(0.0, 1.0).toDouble();
    }
    final base = XpConfig.xpForLevel(stat.level);
    final next = XpConfig.xpForLevel(stat.level + 1);
    return ((stat.currentXp - base) / (next - base)).clamp(0.0, 1.0).toDouble();
  }
}

class _RadarPanel extends StatelessWidget {
  final String statKey;
  final String subStatsJson;

  const _RadarPanel({required this.statKey, required this.subStatsJson});

  @override
  Widget build(BuildContext context) {
    final labels = SubStatsConfig.subStats[statKey] ?? [];
    if (labels.isEmpty) return const SizedBox.shrink();

    return OperatorCard(
      label: 'SUB-STAT RADAR',
      title: 'Building internals',
      icon: Icons.radar_outlined,
      accentColor: BuildingConfig.colorForStat(statKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUB-STAT RADAR', style: OperatorTextStyles.overline),
          const SizedBox(height: 6),
          const Text('Building internals', style: OperatorTextStyles.title),
          const SizedBox(height: 14),
          _RadarChart(statKey: statKey, subStatsJson: subStatsJson),
        ],
      ),
    );
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
          ticksTextStyle: const TextStyle(color: OperatorPalette.textMuted, fontSize: 10),
          gridBorderData: const BorderSide(color: OperatorPalette.borderDim, width: 1),
          titleTextStyle: const TextStyle(color: OperatorPalette.textPrimary, fontSize: 12),
        ),
      ),
    );
  }
}

class _AddQuestForm extends StatelessWidget {
  final String statKey;
  final TextEditingController titleController;
  final QuestTier selectedTier;
  final ValueChanged<QuestTier> onTierChanged;
  final VoidCallback onCreate;
  final Color color;

  const _AddQuestForm({
    required this.statKey,
    required this.titleController,
    required this.selectedTier,
    required this.onTierChanged,
    required this.onCreate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OperatorCard(
      label: 'MISSION FORGE',
      title: 'Create a mission for ${OperatorCopy.shortStatLabel(statKey)}.',
      icon: Icons.add_task_outlined,
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('MISSION FORGE', style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text('Create a mission for ${OperatorCopy.shortStatLabel(statKey)}.', style: OperatorTextStyles.title),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Mission title',
              hintText: 'What action will grow this building?',
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QuestTier>(
            initialValue: selectedTier,
            decoration: InputDecoration(
              labelText: 'Mission tier',
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: QuestTier.values.map((tier) {
              return DropdownMenuItem(
                value: tier,
                child: Text('${OperatorCopy.missionTier(tier.name)} (${tier.xp} XP)'),
              );
            }).toList(),
            onChanged: (t) => onTierChanged(t!),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Forge Mission'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}
