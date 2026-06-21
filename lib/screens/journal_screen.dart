import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/utils/sign_out_redirect.dart';
import 'package:operator_os/providers/journal_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _sleepHoursController = TextEditingController();
  final _winsController = TextEditingController();
  final _lessonController = TextEditingController();
  final _tomorrowController = TextEditingController();
  final _bigPictureController = TextEditingController();

  Mood _mood = Mood.okay;
  SleepQuality? _sleepQuality;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final entry = await ref.read(journalRepositoryProvider).getEntryForDate(userId, DateTime.now());
    if (entry != null && mounted) {
      setState(() {
        _mood = Mood.values.byName(entry.mood);
        _sleepQuality = entry.sleepQuality != null ? SleepQuality.values.byName(entry.sleepQuality!) : null;
        _sleepHoursController.text = entry.sleepHours?.toString() ?? '';
        _winsController.text = entry.wins;
        _lessonController.text = entry.lessonLearned;
        _tomorrowController.text = entry.tomorrowPlan;
        _bigPictureController.text = entry.bigPictureNote;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _sleepHoursController.dispose();
    _winsController.dispose();
    _lessonController.dispose();
    _tomorrowController.dispose();
    _bigPictureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final historyAsync = ref.watch(journalHistoryProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOutAndReturnToLogin(context, ref),
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
            historyAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Text(
                    'No entries yet.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return Column(
                  children: entries.map((e) => _JournalEntryCard(entry: e)).toList(),
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
          'Today\'s Entry',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Mood>(
          initialValue: _mood,
          decoration: const InputDecoration(
            labelText: 'Mood',
            border: OutlineInputBorder(),
          ),
          items: Mood.values.map((m) => DropdownMenuItem<Mood>(
            value: m,
            child: Text(m.name.toUpperCase()),
          )).toList(),
          onChanged: (v) => setState(() => _mood = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sleepHoursController,
          decoration: const InputDecoration(
            labelText: 'Sleep Hours',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SleepQuality>(
          initialValue: _sleepQuality,
          decoration: const InputDecoration(
            labelText: 'Sleep Quality',
            border: OutlineInputBorder(),
          ),
          items: SleepQuality.values.map((s) => DropdownMenuItem<SleepQuality>(
            value: s,
            child: Text(s.name.toUpperCase()),
          )).toList(),
          onChanged: (v) => setState(() => _sleepQuality = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _winsController,
          decoration: const InputDecoration(
            labelText: 'Wins',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _lessonController,
          decoration: const InputDecoration(
            labelText: 'Lesson Learned',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tomorrowController,
          decoration: const InputDecoration(
            labelText: 'Tomorrow Plan',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bigPictureController,
          decoration: const InputDecoration(
            labelText: 'Big Picture Note',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: userId == null ? null : _save,
          child: const Text('Save Entry'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final sleepHours = double.tryParse(_sleepHoursController.text.trim());

    await ref.read(journalRepositoryProvider).saveEntry(
      userId: userId,
      date: DateTime.now(),
      mood: _mood,
      sleepHours: sleepHours,
      sleepQuality: _sleepQuality,
      wins: _winsController.text.trim(),
      lessonLearned: _lessonController.text.trim(),
      tomorrowPlan: _tomorrowController.text.trim(),
      bigPictureNote: _bigPictureController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved.')),
      );
    }
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  static final _dateFormat = DateFormat('MMM d, yyyy');

  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.date);

    return Card(
      child: ListTile(
        title: Text(_dateFormat.format(date)),
        subtitle: Text(
          '${entry.mood.toUpperCase()}'
          '${entry.sleepHours != null ? " • ${entry.sleepHours}h sleep" : ""}',
        ),
        trailing: entry.sleepQuality != null
            ? Text(entry.sleepQuality!.toUpperCase())
            : null,
      ),
    );
  }
}
