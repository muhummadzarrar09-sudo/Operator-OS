import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/campaign_config.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/campaign_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/screens/campaign_season_screen.dart';
import 'package:operator_os/screens/compound_screen.dart';
import 'package:operator_os/services/memory_archive_refresh.dart';
import 'package:operator_os/widgets/mission_complete_ceremony.dart';
import 'package:operator_os/widgets/operator_card.dart';
import 'package:operator_os/widgets/operator_world_hud.dart';
import 'package:operator_os/widgets/quest_list_tile.dart';
import 'package:operator_os/widgets/world_empty_state.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final questsAsync = ref.watch(todayQuestsProvider);
    final activeCampaignAsync = ref.watch(activeCampaignProvider);
    final statsAsync = ref.watch(statsStreamProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
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
      body: questsAsync.when(
        data: (quests) {
          if (quests.isEmpty) {
            return WorldEmptyState(
              icon: Icons.assignment_outlined,
              label: 'QUEST BOARD',
              title: 'The quest board is empty.',
              body: 'Choose your next move, Operator. Inspect the Compound and strengthen the building that needs you most.',
              actionLabel: 'Open Compound',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompoundScreen()),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DirectiveCard(activeCampaign: activeCampaignAsync.asData?.value),
              const SizedBox(height: 14),
              OperatorWorldHud(
                compoundLevel: statsAsync.asData?.value.fold<int>(0, (sum, stat) => sum + stat.level) ?? 0,
                totalXp: statsAsync.asData?.value.fold<int>(0, (sum, stat) => sum + stat.currentXp) ?? 0,
                activeMissions: quests.length,
                campaignLabel: _campaignHudLabel(activeCampaignAsync.asData?.value),
                councilLabel: 'Brief Ready',
                compact: true,
              ),
              const SizedBox(height: 14),
              _WarBriefCard(activeMissionCount: quests.length),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Text('MISSION BOARD', style: OperatorTextStyles.overline),
                  const Spacer(),
                  Text(
                    '${quests.length} active',
                    style: OperatorTextStyles.muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...quests.map(
                (quest) => QuestListTile(
                  quest: quest,
                  showDomain: true,
                  onComplete: userId == null
                      ? null
                      : () async {
                          await ref
                              .read(questsRepositoryProvider)
                              .completeQuest(userId, quest.id);
                          await refreshMemoryArchive(ref);
                          if (!context.mounted) return;
                          await showMissionCompleteCeremony(
                            context: context,
                            statKey: quest.domain,
                            xp: quest.xpValue,
                          );
                        },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

String _campaignHudLabel(ActiveCampaign? activeCampaign) {
  if (activeCampaign == null || !activeCampaign.hasCampaign) return 'No Season';
  return 'Day ${activeCampaign.dayNumber}';
}

class _DirectiveCard extends StatelessWidget {
  final ActiveCampaign? activeCampaign;

  const _DirectiveCard({required this.activeCampaign});

  @override
  Widget build(BuildContext context) {
    final active = activeCampaign;
    final hasCampaign = active != null && active.hasCampaign;
    return OperatorCard(
      label: hasCampaign ? 'ACTIVE CAMPAIGN' : 'OPERATOR DIRECTIVE',
      title: hasCampaign ? active.season!.name : 'Complete today’s missions.',
      body: hasCampaign
          ? 'Day ${active.dayNumber}/${active.season!.durationDays} • ${active.season!.directive}'
          : 'Every finished mission strengthens a building inside the Compound.',
      icon: hasCampaign ? Icons.flag_outlined : Icons.shield_moon_outlined,
      accentColor: OperatorPalette.parchmentGold,
      trailing: IconButton(
        tooltip: 'Campaign Seasons',
        icon: const Icon(Icons.chevron_right, color: OperatorPalette.textSecondary),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CampaignSeasonScreen()),
        ),
      ),
    );
  }
}

class _WarBriefCard extends StatelessWidget {
  final int activeMissionCount;

  const _WarBriefCard({required this.activeMissionCount});

  @override
  Widget build(BuildContext context) {
    final plural = activeMissionCount == 1 ? 'mission is' : 'missions are';
    return OperatorCard(
      label: 'WAR COUNCIL BRIEF',
      title: 'The board is active.',
      body: '$activeMissionCount $plural waiting. Win the day by completing one meaningful action before the world gets noisy.',
      icon: Icons.psychology_alt_outlined,
      accentColor: OperatorPalette.hologramBlue,
    );
  }
}
