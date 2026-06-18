import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/journal_provider.dart';
import 'package:operator_os/services/memory_archive_refresh.dart';
import 'package:operator_os/widgets/operator_card.dart';

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
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: const Text('Reflection Chamber'),
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
              label: 'REFLECTION CHAMBER',
              title: 'Archive the signal.',
              body: 'Wins, lessons, plans, and big-picture notes become memory records for the War Council.',
              icon: Icons.auto_stories_outlined,
              accentColor: OperatorPalette.hologramBlue,
            ),
            const SizedBox(height: 16),
            _buildForm(userId),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('MEMORY TRAIL', style: OperatorTextStyles.overline),
                const Spacer(),
                historyAsync.maybeWhen(
                  data: (entries) => Text('${entries.length} records', style: OperatorTextStyles.muted),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            historyAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const OperatorCard(
                    label: 'NO MEMORIES',
                    title: 'The archive is empty.',
                    body: 'Save a reflection to give the War Council better memory.',
                    icon: Icons.history_edu_outlined,
                    accentColor: OperatorPalette.warningAmber,
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
    return OperatorCard(
      label: 'TODAY\'S REFLECTION',
      title: _moodLine(_mood),
      icon: Icons.edit_note_outlined,
      accentColor: OperatorPalette.parchmentGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('TODAY\'S REFLECTION', style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text(_moodLine(_mood), style: OperatorTextStyles.title),
          const SizedBox(height: 6),
          const Text('Be honest. The Council can only read what you archive.', style: OperatorTextStyles.body),
          const SizedBox(height: 16),
          DropdownButtonFormField<Mood>(
            initialValue: _mood,
            decoration: _inputDecoration('Mood'),
            items: Mood.values.map((m) => DropdownMenuItem<Mood>(
              value: m,
              child: Text(m.name.toUpperCase()),
            )).toList(),
            onChanged: (v) => setState(() => _mood = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sleepHoursController,
            decoration: _inputDecoration('Sleep Hours'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SleepQuality>(
            initialValue: _sleepQuality,
            decoration: _inputDecoration('Sleep Quality'),
            items: SleepQuality.values.map((s) => DropdownMenuItem<SleepQuality>(
              value: s,
              child: Text(s.name.toUpperCase()),
            )).toList(),
            onChanged: (v) => setState(() => _sleepQuality = v),
          ),
          const SizedBox(height: 12),
          _ReflectionField(controller: _winsController, label: 'Wins', hint: 'What strengthened the Compound today?'),
          const SizedBox(height: 12),
          _ReflectionField(controller: _lessonController, label: 'Lesson Learned', hint: 'What did the day teach you?'),
          const SizedBox(height: 12),
          _ReflectionField(controller: _tomorrowController, label: 'Tomorrow Plan', hint: 'What is the next clean move?'),
          const SizedBox(height: 12),
          _ReflectionField(controller: _bigPictureController, label: 'Big Picture Note', hint: 'What pattern should future you remember?', maxLines: 3),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: userId == null ? null : _save,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive Reflection'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: OperatorPalette.panelDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  String _moodLine(Mood mood) {
    return switch (mood) {
      Mood.drained => 'Signal low. Archive the truth.',
      Mood.okay => 'Stable signal. Capture the pattern.',
      Mood.good => 'Good signal. Lock in the lesson.',
      Mood.great => 'Strong signal. Record the win.',
    };
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

    await refreshMemoryArchive(ref);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: OperatorPalette.panelRaised,
          content: Text('Reflection archived. The War Council remembers.'),
        ),
      );
    }
  }
}

class _ReflectionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _ReflectionField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: OperatorPalette.panelDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      maxLines: maxLines,
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  static final _dateFormat = DateFormat('MMM d, yyyy');

  const _JournalEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(entry.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OperatorCard(
        accentColor: OperatorPalette.hologramBlue,
        child: Row(
          children: [
            const Icon(Icons.history_edu_outlined, color: OperatorPalette.hologramBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateFormat.format(date), style: OperatorTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.mood.toUpperCase()}${entry.sleepHours != null ? " • ${entry.sleepHours}h sleep" : ""}',
                    style: OperatorTextStyles.muted,
                  ),
                ],
              ),
            ),
            if (entry.sleepQuality != null)
              Text(entry.sleepQuality!.toUpperCase(), style: OperatorTextStyles.muted),
          ],
        ),
      ),
    );
  }
}
