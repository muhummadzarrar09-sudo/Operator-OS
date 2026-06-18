import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/campaign_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
import 'package:operator_os/screens/boss_day_screen.dart';
import 'package:operator_os/screens/campaign_council_screen.dart';
import 'package:operator_os/screens/campaign_season_screen.dart';
import 'package:operator_os/screens/roadmap_day_screen.dart';
import 'package:operator_os/widgets/operator_card.dart';
import 'package:operator_os/widgets/world_empty_state.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(roadmapDaysProvider);
    final activeCampaignAsync = ref.watch(activeCampaignProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: const Text('Campaign Map'),
        actions: [
          IconButton(
            tooltip: 'Campaign Seasons',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CampaignSeasonScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Campaign Council',
            icon: const Icon(Icons.psychology_alt_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CampaignCouncilScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: daysAsync.when(
        data: (days) {
          if (days.isEmpty) {
            return WorldEmptyState(
              icon: Icons.route_outlined,
              label: 'CAMPAIGN MAP',
              title: 'No campaign days generated yet.',
              body: 'Once the roadmap initializes, the Council can read the terrain and suggest tactical adjustments.',
              actionLabel: 'Open Council',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CampaignCouncilScreen()),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OperatorCard(
                    label: activeCampaignAsync.asData?.value.hasCampaign == true
                        ? 'ACTIVE CAMPAIGN'
                        : 'CAMPAIGN MAP',
                    title: activeCampaignAsync.asData?.value.hasCampaign == true
                        ? activeCampaignAsync.asData!.value.season!.name
                        : 'Your generated path through the Compound.',
                    body: activeCampaignAsync.asData?.value.hasCampaign == true
                        ? 'Day ${activeCampaignAsync.asData!.value.dayNumber}/${activeCampaignAsync.asData!.value.season!.durationDays} • ${activeCampaignAsync.asData!.value.season!.tagline}'
                        : 'Boss Days, focus slots, and bedtime targets form the campaign terrain. Choose a Campaign Season or ask the Council before making tactical adjustments.',
                    icon: activeCampaignAsync.asData?.value.hasCampaign == true
                        ? Icons.flag_outlined
                        : Icons.route_outlined,
                    accentColor: OperatorPalette.parchmentGold,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Campaign Seasons',
                          icon: const Icon(Icons.flag_outlined, color: OperatorPalette.parchmentGold),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CampaignSeasonScreen()),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ask Council',
                          icon: const Icon(Icons.auto_awesome, color: OperatorPalette.hologramBlue),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CampaignCouncilScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _DayCard(day: days[index - 1]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final RoadmapDay day;
  static final _dateFormat = DateFormat('EEEE, MMM d');

  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(day.date);
    final isToday = _isToday(date);
    final isBoss = day.dayType == 'sundayBoss';
    final color = isBoss ? OperatorPalette.dangerRed : BuildingConfig.colorForStat(day.slotA);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: OperatorGradients.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday ? OperatorPalette.parchmentGold : color.withValues(alpha: 0.42),
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isBoss) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BossDayScreen(date: date)),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RoadmapDayScreen(dayId: day.id)),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CampaignBadge(
                    label: isBoss ? 'BOSS DAY' : (isToday ? 'TODAY' : 'CAMPAIGN DAY'),
                    color: isToday ? OperatorPalette.parchmentGold : color,
                  ),
                  const SizedBox(width: 8),
                  Text('Day ${day.dayNumber}', style: OperatorTextStyles.muted),
                  const Spacer(),
                  if (day.done)
                    const Icon(Icons.check_circle, color: OperatorPalette.successGreen, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(_dateFormat.format(date), style: OperatorTextStyles.title),
              const SizedBox(height: 10),
              if (!isBoss) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SlotBadge(label: 'A', stat: day.slotA),
                    _SlotBadge(label: 'B', stat: day.slotB),
                  ],
                ),
                const SizedBox(height: 8),
              ] else
                const Text('Council Hall opens. Review the week honestly.', style: OperatorTextStyles.body),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined, size: 16, color: OperatorPalette.textMuted),
                  const SizedBox(width: 6),
                  Text('Bedtime: ${day.bedtimeTarget}', style: OperatorTextStyles.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _CampaignBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CampaignBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  final String label;
  final String stat;

  const _SlotBadge({required this.label, required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = BuildingConfig.colorForStat(stat.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        'Slot $label: ${OperatorCopy.shortStatLabel(stat.toLowerCase()).toUpperCase()}',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
