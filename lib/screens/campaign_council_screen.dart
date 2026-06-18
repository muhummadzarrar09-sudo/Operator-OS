import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/campaign_provider.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
import 'package:operator_os/widgets/operator_card.dart';

class CampaignCouncilScreen extends ConsumerStatefulWidget {
  const CampaignCouncilScreen({super.key});

  @override
  ConsumerState<CampaignCouncilScreen> createState() => _CampaignCouncilScreenState();
}

class _CampaignCouncilScreenState extends ConsumerState<CampaignCouncilScreen> {
  bool _loading = false;
  String? _recommendation;

  Future<void> _generate(List<RoadmapDay> days) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _loading = true;
      _recommendation = null;
    });

    try {
      final ai = ref.read(aiServiceProvider);
      final rag = ref.read(ragServiceProvider);
      final activeCampaign = await ref.read(activeCampaignProvider.future);
      final upcoming = _upcomingDays(days).take(7).toList();
      final mapSummary = _mapSummary(upcoming);
      final campaignSummary = activeCampaign.hasCampaign
          ? '${activeCampaign.season!.name} — Day ${activeCampaign.dayNumber}/${activeCampaign.season!.durationDays}. Directive: ${activeCampaign.season!.directive}. Primary stats: ${activeCampaign.season!.primaryStats.join(', ')}.'
          : 'No active Campaign Season selected.';
      final memory = await rag.buildContext(
        userId,
        'campaign roadmap adjustment sleep fatigue missed quests weak stats next week',
        k: 8,
      );

      final prompt = '''You are the Operator OS War Council reviewing the Campaign Map.
Do not claim you changed the roadmap. You can only recommend manual adjustments.
Use the existing roadmap summary and memory context.

Active Campaign:
$campaignSummary

Campaign Map Summary:
$mapSummary

Memory Context:
$memory

Return this structure:
1. MAP READ — what the next days look like
2. ADJUSTMENT — one recommended manual adjustment if needed
3. WHY — reason grounded in the context
4. MISSION SEED — one quest the Operator could add manually
5. WARNING — what not to overdo

Campaign Council Recommendation:''';

      final response = await ai.generateText(prompt, maxTokens: 650);
      setState(() {
        _recommendation = response ?? 'The Campaign Map is quiet. Keep today simple: complete one mission and protect recovery.';
      });
    } catch (e) {
      setState(() => _recommendation = 'Campaign Council error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RoadmapDay> _upcomingDays(List<RoadmapDay> days) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final upcoming = days.where((d) => d.date >= todayStart).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  String _mapSummary(List<RoadmapDay> days) {
    if (days.isEmpty) return 'No upcoming roadmap days available.';
    final dateFormat = DateFormat('EEE MMM d');
    return days.map((day) {
      final date = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(day.date));
      if (day.dayType == 'sundayBoss') {
        return 'Day ${day.dayNumber} ($date): Boss Day, bedtime ${day.bedtimeTarget}, done=${day.done}';
      }
      return 'Day ${day.dayNumber} ($date): Slot A ${day.slotA}, Slot B ${day.slotB}, bedtime ${day.bedtimeTarget}, done=${day.done}';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(roadmapDaysProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(title: const Text('Campaign Council')),
      body: daysAsync.when(
        data: (days) {
          final upcoming = _upcomingDays(days).take(7).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const OperatorCard(
                label: 'AI-ADAPTIVE ROADMAP',
                title: 'Suggest, do not mutate.',
                body: 'The Council can read the Campaign Map and recommend tactical adjustments. It will not silently change your roadmap.',
                icon: Icons.route_outlined,
                accentColor: OperatorPalette.hologramBlue,
              ),
              const SizedBox(height: 16),
              OperatorCard(
                label: 'NEXT 7 DAYS',
                title: upcoming.isEmpty ? 'No upcoming days found.' : 'Upcoming campaign terrain.',
                icon: Icons.map_outlined,
                accentColor: OperatorPalette.parchmentGold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEXT 7 DAYS', style: OperatorTextStyles.overline),
                    const SizedBox(height: 8),
                    Text(
                      upcoming.isEmpty ? 'No upcoming days found.' : 'Upcoming campaign terrain.',
                      style: OperatorTextStyles.title,
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      const Text('Generate roadmap days first, then ask the Council.', style: OperatorTextStyles.body)
                    else
                      ...upcoming.map((day) => _MiniDayRow(day: day)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading || upcoming.isEmpty ? null : () => _generate(days),
                icon: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Reading Campaign Map...' : 'Ask Council for Adjustment'),
              ),
              const SizedBox(height: 16),
              if (_recommendation != null)
                OperatorCard(
                  label: 'COUNCIL RECOMMENDATION',
                  title: 'Manual adjustment only.',
                  body: _recommendation!,
                  icon: Icons.psychology_alt_outlined,
                  accentColor: OperatorPalette.hologramBlue,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _MiniDayRow extends StatelessWidget {
  final RoadmapDay day;

  const _MiniDayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE MMM d').format(DateTime.fromMillisecondsSinceEpoch(day.date));
    final isBoss = day.dayType == 'sundayBoss';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OperatorPalette.voidBlack.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OperatorPalette.borderDim),
      ),
      child: Row(
        children: [
          Text('D${day.dayNumber}', style: OperatorTextStyles.overline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isBoss ? '$date • Boss Day' : '$date • ${day.slotA.toUpperCase()} / ${day.slotB.toUpperCase()}',
              style: OperatorTextStyles.body,
            ),
          ),
          if (day.done) const Icon(Icons.check_circle, color: OperatorPalette.successGreen, size: 18),
        ],
      ),
    );
  }
}
