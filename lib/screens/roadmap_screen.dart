import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/roadmap_provider.dart';
import 'package:operator_os/screens/boss_day_screen.dart';
import 'package:operator_os/screens/roadmap_day_screen.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(roadmapDaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roadmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: daysAsync.when(
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text('No roadmap days generated yet.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (_, index) => _DayCard(day: days[index]),
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
    final color = isBoss ? Colors.redAccent : BuildingConfig.colorForStat(day.slotA);

    return Card(
      shape: isToday
          ? RoundedRectangleBorder(
              side: BorderSide(color: Colors.amber.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      isBoss ? 'BOSS DAY' : 'WEEKDAY',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Day ${day.dayNumber}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  if (day.done)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _dateFormat.format(date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (!isBoss) ...[
                Row(
                  children: [
                    _SlotBadge(label: 'A', stat: day.slotA.toUpperCase()),
                    const SizedBox(width: 8),
                    _SlotBadge(label: 'B', stat: day.slotB.toUpperCase()),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Bedtime: ${day.bedtimeTarget}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
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

class _SlotBadge extends StatelessWidget {
  final String label;
  final String stat;

  const _SlotBadge({required this.label, required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = BuildingConfig.colorForStat(stat.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Slot $label: $stat',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
