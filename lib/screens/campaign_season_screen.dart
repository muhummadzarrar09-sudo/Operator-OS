import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/campaign_config.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/campaign_provider.dart';
import 'package:operator_os/widgets/operator_card.dart';

class CampaignSeasonScreen extends ConsumerWidget {
  const CampaignSeasonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeCampaignProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(title: const Text('Campaign Seasons')),
      body: activeAsync.when(
        data: (active) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OperatorCard(
              label: 'ACTIVE CAMPAIGN',
              title: active.hasCampaign ? active.season!.name : 'No campaign selected.',
              body: active.hasCampaign
                  ? 'Day ${active.dayNumber}/${active.season!.durationDays} • ${active.season!.directive}'
                  : 'Choose the current arc. The app will frame briefs and the Campaign Map around what you are building right now.',
              icon: Icons.flag_outlined,
              accentColor: OperatorPalette.parchmentGold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: OperatorPalette.parchmentGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ACTIVE CAMPAIGN', style: OperatorTextStyles.overline),
                            const SizedBox(height: 4),
                            Text(
                              active.hasCampaign ? active.season!.name : 'No campaign selected.',
                              style: OperatorTextStyles.title,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (active.hasCampaign) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: active.progress,
                        minHeight: 8,
                        backgroundColor: OperatorPalette.borderDim,
                        valueColor: const AlwaysStoppedAnimation(OperatorPalette.parchmentGold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Day ${active.dayNumber}/${active.season!.durationDays} • ${active.daysRemaining} days remaining',
                      style: OperatorTextStyles.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(active.season!.directive, style: OperatorTextStyles.body),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(campaignSeasonStoreProvider).clear();
                        ref.invalidate(activeCampaignProvider);
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Campaign'),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Choose the current arc. The app will frame briefs and the Campaign Map around what you are building right now.',
                      style: OperatorTextStyles.body,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('AVAILABLE CAMPAIGNS', style: OperatorTextStyles.overline),
            const SizedBox(height: 12),
            ...CampaignPresets.all.map(
              (season) => _CampaignSeasonCard(
                season: season,
                active: active.season?.id == season.id,
                onActivate: () async {
                  await ref.read(campaignSeasonStoreProvider).activate(season);
                  ref.invalidate(activeCampaignProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: OperatorPalette.panelRaised,
                      content: Text('Campaign selected: ${season.name}. ${season.tagline}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Campaign error: $err')),
      ),
    );
  }
}

class _CampaignSeasonCard extends StatelessWidget {
  final CampaignSeason season;
  final bool active;
  final VoidCallback onActivate;

  const _CampaignSeasonCard({
    required this.season,
    required this.active,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = BuildingConfig.colorForStat(season.primaryStats.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OperatorCard(
        accentColor: active ? OperatorPalette.successGreen : primaryColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.flag, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${season.durationDays}-DAY CAMPAIGN', style: OperatorTextStyles.overline),
                      const SizedBox(height: 4),
                      Text(season.name, style: OperatorTextStyles.title),
                    ],
                  ),
                ),
                if (active)
                  const Icon(Icons.check_circle, color: OperatorPalette.successGreen),
              ],
            ),
            const SizedBox(height: 10),
            Text(season.tagline, style: OperatorTextStyles.body),
            const SizedBox(height: 6),
            Text(season.description, style: OperatorTextStyles.muted),
            const SizedBox(height: 12),
            _StatLine(label: 'Primary', stats: season.primaryStats),
            const SizedBox(height: 6),
            _StatLine(label: 'Secondary', stats: season.secondaryStats),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: active ? null : onActivate,
              icon: Icon(active ? Icons.check : Icons.flag_outlined),
              label: Text(active ? 'Active Campaign' : 'Start Campaign'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final List<String> stats;

  const _StatLine({required this.label, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$label:', style: OperatorTextStyles.muted),
        ...stats.map((stat) {
          final color = BuildingConfig.colorForStat(stat);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              OperatorCopy.shortStatLabel(stat),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }),
      ],
    );
  }
}
