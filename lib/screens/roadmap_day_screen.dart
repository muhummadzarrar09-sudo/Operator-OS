import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/data/repositories/roadmap_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
import 'package:operator_os/services/memory_archive_refresh.dart';
import 'package:operator_os/widgets/mission_complete_ceremony.dart';
import 'package:operator_os/widgets/operator_card.dart';
import 'package:operator_os/widgets/quest_list_tile.dart';

class RoadmapDayScreen extends ConsumerStatefulWidget {
  final String dayId;

  const RoadmapDayScreen({required this.dayId, super.key});

  @override
  ConsumerState<RoadmapDayScreen> createState() => _RoadmapDayScreenState();
}

class _RoadmapDayScreenState extends ConsumerState<RoadmapDayScreen> {
  final _titleController = TextEditingController();
  String _domain = '';
  QuestTier _tier = QuestTier.standard;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayAsync = ref.watch(roadmapDayProvider(widget.dayId));
    final questsAsync = ref.watch(questsByRoadmapDayProvider(widget.dayId));
    final userId = ref.watch(currentUserIdProvider);

    return dayAsync.when(
      data: (day) {
        if (day == null) {
          return const Scaffold(
            backgroundColor: OperatorPalette.voidBlack,
            body: Center(child: Text('Roadmap day not found.')),
          );
        }
        if (_domain.isEmpty) {
          _domain = day.slotA;
        }
        return Scaffold(
          backgroundColor: OperatorPalette.voidBlack,
          appBar: AppBar(title: Text(_formatDate(day.date))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayHeader(
                  day: day,
                  onToggleDone: (v) => ref.read(roadmapRepositoryProvider).markDayDone(day.id, v),
                ),
                const SizedBox(height: 18),
                if (day.dayType != DayType.sundayBoss.name) ...[
                  Row(
                    children: [
                      Expanded(child: _SlotPanel(label: 'Slot A', statKey: day.slotA)),
                      const SizedBox(width: 12),
                      Expanded(child: _SlotPanel(label: 'Slot B', statKey: day.slotB)),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Row(
                  children: [
                    const Text('LINKED MISSIONS', style: OperatorTextStyles.overline),
                    const Spacer(),
                    questsAsync.maybeWhen(
                      data: (quests) => Text('${quests.length} linked', style: OperatorTextStyles.muted),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                questsAsync.when(
                  data: (quests) {
                    if (quests.isEmpty) {
                      return const OperatorCard(
                        label: 'NO LINKED MISSIONS',
                        title: 'This campaign node is empty.',
                        body: 'Forge a mission below to make this day actionable.',
                        icon: Icons.assignment_outlined,
                        accentColor: OperatorPalette.warningAmber,
                      );
                    }
                    return Column(
                      children: quests.map((q) => QuestListTile(
                        quest: q,
                        showDomain: true,
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
                  error: (err, _) => Text('Error: $err'),
                ),
                const SizedBox(height: 18),
                _AddQuestForm(
                  day: day,
                  userId: userId,
                  titleController: _titleController,
                  domain: _domain,
                  tier: _tier,
                  onDomainChanged: (d) => setState(() => _domain = d),
                  onTierChanged: (t) => setState(() => _tier = t),
                  onCreate: () => _createQuest(userId, day),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: OperatorPalette.voidBlack,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: OperatorPalette.voidBlack,
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  String _formatDate(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  Future<void> _createQuest(String? userId, RoadmapDay day) async {
    if (userId == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await ref.read(questsRepositoryProvider).createQuest(
      userId: userId,
      domain: _domain,
      title: title,
      tier: _tier,
      roadmapDayId: day.id,
    );

    _titleController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: OperatorPalette.panelRaised,
          content: Text('Mission forged for this campaign node.'),
        ),
      );
    }
  }
}

class _DayHeader extends StatelessWidget {
  final RoadmapDay day;
  final ValueChanged<bool>? onToggleDone;
  static final _dateFormat = DateFormat('EEEE, MMM d, yyyy');

  const _DayHeader({required this.day, this.onToggleDone});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(day.date);
    final isBoss = day.dayType == DayType.sundayBoss.name;
    final color = isBoss ? OperatorPalette.dangerRed : BuildingConfig.colorForStat(day.slotA);

    return OperatorCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Text(
                  isBoss ? 'BOSS NODE' : 'CAMPAIGN NODE',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text('Day ${day.dayNumber}', style: OperatorTextStyles.muted),
            ],
          ),
          const SizedBox(height: 12),
          Text(_dateFormat.format(date), style: OperatorTextStyles.title),
          const SizedBox(height: 8),
          Text(
            isBoss
                ? 'Council Hall opens. Review the week honestly.'
                : 'Execute the day. Protect the bedtime target. Keep the campaign moving.',
            style: OperatorTextStyles.body,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.bedtime_outlined, size: 18, color: OperatorPalette.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text('Bedtime target: ${day.bedtimeTarget}', style: OperatorTextStyles.muted)),
              const SizedBox(width: 8),
              const Text('Done', style: OperatorTextStyles.muted),
              Checkbox(
                value: day.done,
                onChanged: (v) {
                  if (v != null && onToggleDone != null) {
                    onToggleDone!(v);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotPanel extends StatelessWidget {
  final String label;
  final String statKey;

  const _SlotPanel({required this.label, required this.statKey});

  @override
  Widget build(BuildContext context) {
    final color = BuildingConfig.colorForStat(statKey);
    return OperatorCard(
      accentColor: color,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text(OperatorCopy.shortStatLabel(statKey), style: OperatorTextStyles.title),
          const SizedBox(height: 6),
          Text(OperatorCopy.statLabel(statKey), style: OperatorTextStyles.muted),
        ],
      ),
    );
  }
}

class _AddQuestForm extends StatelessWidget {
  final RoadmapDay day;
  final String? userId;
  final TextEditingController titleController;
  final String domain;
  final QuestTier tier;
  final ValueChanged<String> onDomainChanged;
  final ValueChanged<QuestTier> onTierChanged;
  final VoidCallback onCreate;

  const _AddQuestForm({
    required this.day,
    required this.userId,
    required this.titleController,
    required this.domain,
    required this.tier,
    required this.onDomainChanged,
    required this.onTierChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isBoss = day.dayType == DayType.sundayBoss.name;
    final domainItems = isBoss
        ? StatKey.values.map((k) => k.name).toList()
        : [day.slotA, day.slotB];

    return OperatorCard(
      label: 'MISSION FORGE',
      title: 'Add mission to this node.',
      icon: Icons.add_task_outlined,
      accentColor: OperatorPalette.parchmentGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('MISSION FORGE', style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          const Text('Add mission to this node.', style: OperatorTextStyles.title),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Mission Title',
              hintText: 'What action belongs on this day?',
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: domainItems.contains(domain) ? domain : domainItems.first,
            decoration: InputDecoration(
              labelText: 'Building',
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: domainItems.map((d) => DropdownMenuItem<String>(
              value: d,
              child: Text(OperatorCopy.statLabel(d)),
            )).toList(),
            onChanged: (v) => onDomainChanged(v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QuestTier>(
            initialValue: tier,
            decoration: InputDecoration(
              labelText: 'Mission Tier',
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            items: QuestTier.values.map((t) => DropdownMenuItem<QuestTier>(
              value: t,
              child: Text('${OperatorCopy.missionTier(t.name)} (${t.xp} XP)'),
            )).toList(),
            onChanged: (v) => onTierChanged(v!),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: userId == null ? null : onCreate,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Forge Node Mission'),
          ),
        ],
      ),
    );
  }
}
