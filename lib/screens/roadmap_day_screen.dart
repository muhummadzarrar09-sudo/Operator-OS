import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/data/repositories/roadmap_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
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
          return Scaffold(
            appBar: AppBar(title: const Text('Day Not Found')),
            body: const Center(child: Text('Roadmap day not found.')),
          );
        }
        if (_domain.isEmpty) {
          _domain = day.slotA;
        }
        return Scaffold(
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
                const SizedBox(height: 24),
                const Text(
                  'Linked Quests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                questsAsync.when(
                  data: (quests) {
                    if (quests.isEmpty) {
                      return const Text(
                        'No quests linked to this day.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    return Column(
                      children: quests.map((q) => QuestListTile(
                        quest: q,
                        showDomain: true,
                        onComplete: userId == null
                            ? null
                            : () => ref.read(questsRepositoryProvider).completeQuest(userId, q.id),
                      )).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => Text('Error: $err'),
                ),
                const Divider(height: 32),
                const Text(
                  'Add Quest for This Day',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
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
        const SnackBar(content: Text('Quest created.')),
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
    final isBoss = day.dayType == 'sundayBoss';
    final color = isBoss ? Colors.redAccent : BuildingConfig.colorForStat(day.slotA);

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
                    isBoss ? 'BOSS DAY' : 'WEEKDAY',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  'Day ${day.dayNumber}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _dateFormat.format(date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (!isBoss) ...[
              Row(
                children: [
                  _SlotRow(label: 'Slot A', value: day.slotA.toUpperCase()),
                  const SizedBox(width: 16),
                  _SlotRow(label: 'Slot B', value: day.slotB.toUpperCase()),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text('Bedtime target: ${day.bedtimeTarget}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Done:'),
                const SizedBox(width: 8),
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
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String label;
  final String value;

  const _SlotRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = BuildingConfig.colorForStat(value.toLowerCase());
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
    final isBoss = day.dayType == 'sundayBoss';
    final domainItems = isBoss
        ? StatKey.values.map((k) => k.name).toList()
        : [day.slotA, day.slotB];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Quest Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: domainItems.contains(domain) ? domain : domainItems.first,
          decoration: const InputDecoration(
            labelText: 'Domain',
            border: OutlineInputBorder(),
          ),
          items: domainItems.map((d) => DropdownMenuItem<String>(
            value: d,
            child: Text(d.toUpperCase()),
          )).toList(),
          onChanged: (v) => onDomainChanged(v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<QuestTier>(
          initialValue: tier,
          decoration: const InputDecoration(
            labelText: 'Tier',
            border: OutlineInputBorder(),
          ),
          items: QuestTier.values.map((t) => DropdownMenuItem<QuestTier>(
            value: t,
            child: Text('${t.name} (${t.xp} XP)'),
          )).toList(),
          onChanged: (v) => onTierChanged(v!),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: userId == null ? null : onCreate,
          child: const Text('Create Quest'),
        ),
      ],
    );
  }
}
