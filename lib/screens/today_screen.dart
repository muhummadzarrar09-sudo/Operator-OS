import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/screens/campaign_season_screen.dart';
import 'package:operator_os/screens/compound_screen.dart';
import 'package:operator_os/screens/journal_screen.dart';
import 'package:operator_os/screens/roadmap_screen.dart';
import 'package:operator_os/screens/sleep_log_screen.dart';
import 'package:operator_os/widgets/operator_card.dart';
import 'package:operator_os/widgets/quest_list_tile.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final questsAsync = ref.watch(todayQuestsProvider);
    final statsAsync = ref.watch(statsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => questsAsync.when(
          data: (quests) => _CommandBody(
            stats: stats,
            quests: quests,
            userId: userId,
            onCompleteQuest: userId == null
                ? null
                : (quest) => ref.read(questsRepositoryProvider).completeQuest(userId, quest.id),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Quest error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Stats error: $err')),
      ),
    );
  }
}

class _CommandBody extends StatelessWidget {
  final List<Stat> stats;
  final List<Quest> quests;
  final String? userId;
  final ValueChanged<Quest>? onCompleteQuest;

  const _CommandBody({
    required this.stats,
    required this.quests,
    required this.userId,
    required this.onCompleteQuest,
  });

  @override
  Widget build(BuildContext context) {
    final totalXp = stats.fold<int>(0, (sum, stat) => sum + stat.currentXp);
    final compoundLevel = stats.isEmpty
        ? 1
        : (stats.fold<int>(0, (sum, stat) => sum + stat.level) / stats.length).floor();

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OperatorPalette.voidBlack,
                  OperatorPalette.nightNavy,
                  Color(0xFF0B111C),
                ],
              ),
            ),
          ),
        ),
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _HeroCommandCard(
                    compoundLevel: compoundLevel,
                    totalXp: totalXp,
                    activeMissions: quests.length,
                    isLocalMode: userId == localOperatorUserId,
                  ),
                  const SizedBox(height: 16),
                  _QuickLaunchGrid(),
                  const SizedBox(height: 20),
                  Text('TODAY\'S MISSIONS', style: OperatorTextStyles.overline),
                  const SizedBox(height: 10),
                  if (quests.isEmpty)
                    OperatorCard(
                      icon: Icons.check_circle_outline,
                      label: 'CLEAR BOARD',
                      title: 'No missions due today.',
                      body: 'Open the Compound to inspect your stats, or create a quest from any building.',
                      trailing: const Icon(Icons.arrow_forward, color: OperatorPalette.parchmentGold),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const CompoundScreen()),
                      ),
                    )
                  else
                    ...quests.map(
                      (quest) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QuestListTile(
                          quest: quest,
                          showDomain: true,
                          onComplete: onCompleteQuest == null ? null : () => onCompleteQuest!(quest),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCommandCard extends StatelessWidget {
  final int compoundLevel;
  final int totalXp;
  final int activeMissions;
  final bool isLocalMode;

  const _HeroCommandCard({
    required this.compoundLevel,
    required this.totalXp,
    required this.activeMissions,
    required this.isLocalMode,
  });

  @override
  Widget build(BuildContext context) {
    return OperatorCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [Color(0x33FF8A2A), Color(0x00151A2E)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: OperatorPalette.parchmentGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OperatorPalette.parchmentGold.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.shield_moon_outlined, color: OperatorPalette.parchmentGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isLocalMode ? 'PERSONAL MODE' : 'ONLINE MODE', style: OperatorTextStyles.overline),
                      const SizedBox(height: 4),
                      const Text('Run today. Build the base.', style: OperatorTextStyles.title),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _MetricPill(label: 'Compound', value: 'Lv $compoundLevel')),
                const SizedBox(width: 8),
                Expanded(child: _MetricPill(label: 'XP', value: _format(totalXp))),
                const SizedBox(width: 8),
                Expanded(child: _MetricPill(label: 'Missions', value: '$activeMissions')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: OperatorPalette.voidBlack.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: OperatorPalette.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: OperatorTextStyles.muted.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: OperatorPalette.parchmentGold, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _QuickLaunchGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.castle_outlined,
        title: 'Compound',
        subtitle: 'Your 8 stats',
        color: OperatorPalette.parchmentGold,
        page: const CompoundScreen(),
      ),
      _QuickAction(
        icon: Icons.book_outlined,
        title: 'Journal',
        subtitle: 'Log wins',
        color: OperatorPalette.hologramBlue,
        page: const JournalScreen(),
      ),
      _QuickAction(
        icon: Icons.bedtime_outlined,
        title: 'Sleep',
        subtitle: 'Recovery',
        color: OperatorPalette.successGreen,
        page: const SleepLogScreen(),
      ),
      _QuickAction(
        icon: Icons.route_outlined,
        title: 'Roadmap',
        subtitle: 'Plan days',
        color: OperatorPalette.torchOrange,
        page: const RoadmapScreen(),
      ),
      _QuickAction(
        icon: Icons.flag_outlined,
        title: 'Campaign',
        subtitle: 'Focus season',
        color: OperatorPalette.warningAmber,
        page: const CampaignSeasonScreen(),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((action) => _QuickActionTile(action: action)).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 154,
      child: Material(
        color: OperatorPalette.panelDark.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => action.page),
          ),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: action.color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(action.icon, color: action.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(action.subtitle, overflow: TextOverflow.ellipsis, style: OperatorTextStyles.muted.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
