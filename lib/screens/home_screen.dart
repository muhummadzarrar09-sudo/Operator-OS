import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/repositories/habits_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/habits_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/providers/user_initializer.dart';
import 'package:operator_os/data/database.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure user initializer is active.
    ref.watch(userInitializerProvider);

    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(statsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator OS — Phase 1 Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authState.when(
              data: (state) => Text(
                'User: ${state.session?.user.email ?? state.session?.user.id ?? "Unknown"}',
                style: const TextStyle(color: Colors.grey),
              ),
              loading: () => const Text('Loading auth...'),
              error: (err, stack) => Text('Auth error: $err'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stats (stream)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            statsAsync.when(
              data: (stats) => _StatsList(stats: stats, ref: ref),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Stats error: $err'),
            ),
            const Divider(height: 32),
            _QuestDebugSection(ref: ref),
            const Divider(height: 32),
            _HabitDebugSection(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _StatsList extends StatelessWidget {
  final List<Stat> stats;
  final WidgetRef ref;

  const _StatsList({required this.stats, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Text('No stats seeded yet (check initializer).');
    }
    return Column(
      children: stats.map((stat) {
        final tier = XpConfig.tierForLevel(stat.level);
        return Card(
          child: ListTile(
            title: Text(stat.statKey.toUpperCase()),
            subtitle: Text('Lv ${stat.level}  |  XP ${stat.currentXp}  |  Tier $tier'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Text('+10'),
                  onPressed: () => _addXp(stat.statKey, 10),
                ),
                IconButton(
                  icon: const Text('+25'),
                  onPressed: () => _addXp(stat.statKey, 25),
                ),
                IconButton(
                  icon: const Text('+75'),
                  onPressed: () => _addXp(stat.statKey, 75),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _addXp(String statKey, int xp) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref.read(statsRepositoryProvider).addXp(userId, statKey, xp);
  }
}

class _QuestDebugSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _QuestDebugSection({required this.ref});

  @override
  ConsumerState<_QuestDebugSection> createState() => _QuestDebugSectionState();
}

class _QuestDebugSectionState extends ConsumerState<_QuestDebugSection> {
  String _domain = StatKey.forge.name;
  QuestTier _tier = QuestTier.standard;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final questsAsync = ref.watch(questsByDomainStreamProvider(_domain));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quest Debug',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _domain,
          isExpanded: true,
          items: StatKey.values.map((k) => DropdownMenuItem(value: k.name, child: Text(k.name))).toList(),
          onChanged: (v) => setState(() => _domain = v!),
        ),
        DropdownButton<QuestTier>(
          value: _tier,
          isExpanded: true,
          items: QuestTier.values.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (${t.xp} XP)'))).toList(),
          onChanged: (v) => setState(() => _tier = v!),
        ),
        ElevatedButton(
          onPressed: userId == null
              ? null
              : () => ref.read(questsRepositoryProvider).createQuest(
                    userId: userId,
                    domain: _domain,
                    title: 'Test quest ${_tier.name}',
                    tier: _tier,
                  ),
          child: const Text('Create Quest'),
        ),
        const SizedBox(height: 8),
        questsAsync.when(
          data: (quests) => Column(
            children: quests.map((q) => ListTile(
              title: Text(q.title),
              subtitle: Text('${q.domain} • ${q.tier} • ${q.xpValue} XP'),
              trailing: ElevatedButton(
                onPressed: userId == null
                    ? null
                    : () => ref.read(questsRepositoryProvider).completeQuest(userId, q.id),
                child: const Text('Done'),
              ),
            )).toList(),
          ),
          loading: () => const Text('Loading quests...'),
          error: (err, stack) => Text('Quest error: $err'),
        ),
      ],
    );
  }
}

class _HabitDebugSection extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _HabitDebugSection({required this.ref});

  @override
  ConsumerState<_HabitDebugSection> createState() => _HabitDebugSectionState();
}

class _HabitDebugSectionState extends ConsumerState<_HabitDebugSection> {
  String _domain = StatKey.vitality.name;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final habitsAsync = ref.watch(habitsByDomainStreamProvider(_domain));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Habit Debug',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _domain,
          isExpanded: true,
          items: StatKey.values.map((k) => DropdownMenuItem(value: k.name, child: Text(k.name))).toList(),
          onChanged: (v) => setState(() => _domain = v!),
        ),
        ElevatedButton(
          onPressed: userId == null
              ? null
              : () => ref.read(habitsRepositoryProvider).createHabit(
                    userId: userId,
                    domain: _domain,
                    name: 'Test habit',
                    cadence: 'daily',
                  ),
          child: const Text('Create Habit'),
        ),
        const SizedBox(height: 8),
        habitsAsync.when(
          data: (habits) => Column(
            children: habits.map((h) => ListTile(
              title: Text(h.name),
              subtitle: Text('Streak: ${h.currentStreak}  |  Skips: ${h.skipTokensRemaining}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => ref.read(habitsRepositoryProvider).recordHabitCompletion(h.id),
                    child: const Text('✓'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => ref.read(habitsRepositoryProvider).recordHabitMiss(h.id),
                    child: const Text('✗'),
                  ),
                ],
              ),
            )).toList(),
          ),
          loading: () => const Text('Loading habits...'),
          error: (err, stack) => Text('Habit error: $err'),
        ),
      ],
    );
  }
}
