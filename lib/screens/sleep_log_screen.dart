import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/sleep_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/sleep_provider.dart';

class SleepLogScreen extends ConsumerStatefulWidget {
  const SleepLogScreen({super.key});

  @override
  ConsumerState<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends ConsumerState<SleepLogScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);

  static final _timeFormat = DateFormat('h:mm a');
  static final _dateFormat = DateFormat('EEE, MMM d');

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final sleepAsync = ref.watch(sleepLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Log'),
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
            _buildForm(userId),
            const Divider(height: 32),
            const Text(
              'History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            sleepAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Text(
                    'No sleep logs yet.',
                    style: TextStyle(color: Colors.grey),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Log Tonight',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.bedtime),
          title: const Text('Bedtime'),
          subtitle: Text(_timeFormat.format(_timeToDate(_bedtime))),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickTime(context, _bedtime, (t) => setState(() => _bedtime = t)),
        ),
        ListTile(
          leading: const Icon(Icons.wb_sunny),
          title: const Text('Wake Time'),
          subtitle: Text(_timeFormat.format(_timeToDate(_wakeTime))),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickTime(context, _wakeTime, (t) => setState(() => _wakeTime = t)),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: userId == null ? null : () => _save(userId),
          child: const Text('Save Sleep Log'),
        ),
      ],
    );
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
        const SnackBar(content: Text('Sleep logged.')),
      );
    }
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

    return Card(
      child: ListTile(
        leading: Icon(
          log.onTarget ? Icons.check_circle : Icons.error_outline,
          color: log.onTarget ? Colors.green : Colors.orange,
        ),
        title: Text(_dateFormat.format(date)),
        subtitle: Text(
          '${_timeFormat.format(bedtime)} → ${_timeFormat.format(wake)} • '
          '${log.durationHours.toStringAsFixed(1)}h',
        ),
        trailing: log.onTarget
            ? const Text('+25 XP', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            : null,
      ),
    );
  }
}
