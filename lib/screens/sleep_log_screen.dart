import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/sleep_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/sleep_provider.dart';
import 'package:operator_os/widgets/operator_card.dart';

class SleepLogScreen extends ConsumerStatefulWidget {
  const SleepLogScreen({super.key});

  @override
  ConsumerState<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends ConsumerState<SleepLogScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);

  static final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final sleepAsync = ref.watch(sleepLogsProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: const Text('Recovery Shrine'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
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
            const OperatorCard(
              label: 'RECOVERY SHRINE',
              title: 'Recovery is production.',
              body: 'Sleep protects tomorrow’s missions. Hit the target and Vitality gains recovery XP.',
              icon: Icons.bedtime_outlined,
              accentColor: OperatorPalette.hologramBlue,
            ),
            const SizedBox(height: 16),
            _buildForm(userId),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('RECOVERY LOG', style: OperatorTextStyles.overline),
                const Spacer(),
                sleepAsync.maybeWhen(
                  data: (logs) => Text('${logs.length} records', style: OperatorTextStyles.muted),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            sleepAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const OperatorCard(
                    label: 'NO RECORDS',
                    title: 'The Shrine is quiet.',
                    body: 'Log sleep to start tracking recovery and protecting the next day’s output.',
                    icon: Icons.nightlight_round,
                    accentColor: OperatorPalette.warningAmber,
                  );
                }
                return Column(
                  children: logs.map((l) => _SleepLogCard(log: l)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(String? userId) {
    final estimatedHours = _estimatedDurationHours();
    return OperatorCard(
      label: 'TONIGHT\'S RECOVERY',
      title: '${estimatedHours.toStringAsFixed(1)}h planned',
      icon: Icons.spa_outlined,
      accentColor: OperatorPalette.parchmentGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('TONIGHT\'S RECOVERY', style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text('${estimatedHours.toStringAsFixed(1)}h planned', style: OperatorTextStyles.title),
          const SizedBox(height: 6),
          const Text('Protect the night. Tomorrow’s Compound runs on this.', style: OperatorTextStyles.body),
          const SizedBox(height: 16),
          _TimeTile(
            icon: Icons.bedtime,
            title: 'Bedtime',
            value: _timeFormat.format(_timeToDate(_bedtime)),
            onTap: () => _pickTime(context, _bedtime, (t) => setState(() => _bedtime = t)),
          ),
          const SizedBox(height: 10),
          _TimeTile(
            icon: Icons.wb_sunny_outlined,
            title: 'Wake Time',
            value: _timeFormat.format(_timeToDate(_wakeTime)),
            onTap: () => _pickTime(context, _wakeTime, (t) => setState(() => _wakeTime = t)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: userId == null ? null : () => _save(userId),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Seal Recovery Log'),
          ),
        ],
      ),
    );
  }

  double _estimatedDurationHours() {
    final bedtime = _timeToDate(_bedtime);
    var wakeTime = _timeToDate(_wakeTime);
    if (wakeTime.isBefore(bedtime)) wakeTime = wakeTime.add(const Duration(days: 1));
    return wakeTime.difference(bedtime).inMinutes / 60.0;
  }

  DateTime _timeToDate(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save(String userId) async {
    final now = DateTime.now();
    final bedtime = DateTime(now.year, now.month, now.day, _bedtime.hour, _bedtime.minute);
    var wakeTime = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    if (wakeTime.isBefore(bedtime)) {
      wakeTime = wakeTime.add(const Duration(days: 1));
    }

    await ref.read(sleepRepositoryProvider).createSleepLog(
      userId: userId,
      date: now,
      bedtime: bedtime,
      wakeTime: wakeTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: OperatorPalette.panelRaised,
          content: Text('Recovery logged. The Vitality Grounds remember.'),
        ),
      );
    }
  }
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _TimeTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OperatorPalette.voidBlack.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OperatorPalette.borderDim),
        ),
        child: Row(
          children: [
            Icon(icon, color: OperatorPalette.parchmentGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OperatorTextStyles.muted),
                  const SizedBox(height: 2),
                  Text(value, style: OperatorTextStyles.body),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: OperatorPalette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SleepLogCard extends StatelessWidget {
  final SleepLog log;
  static final _dateFormat = DateFormat('EEE, MMM d');
  static final _timeFormat = DateFormat('h:mm a');

  const _SleepLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(log.date);
    final bedtime = DateTime.fromMillisecondsSinceEpoch(log.bedtime);
    final wake = DateTime.fromMillisecondsSinceEpoch(log.wakeTime);
    final color = log.onTarget ? OperatorPalette.successGreen : OperatorPalette.warningAmber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OperatorCard(
        accentColor: color,
        child: Row(
          children: [
            Icon(log.onTarget ? Icons.check_circle : Icons.error_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateFormat.format(date), style: OperatorTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    '${_timeFormat.format(bedtime)} → ${_timeFormat.format(wake)} • ${log.durationHours.toStringAsFixed(1)}h',
                    style: OperatorTextStyles.muted,
                  ),
                ],
              ),
            ),
            if (log.onTarget)
              const Text('+25 XP', style: TextStyle(color: OperatorPalette.successGreen, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
