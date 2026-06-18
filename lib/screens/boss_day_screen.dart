import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/repositories/boss_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/services/memory_archive_refresh.dart';
import 'package:operator_os/widgets/operator_card.dart';

class BossDayScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const BossDayScreen({required this.date, super.key});

  @override
  ConsumerState<BossDayScreen> createState() => _BossDayScreenState();
}

class _BossDayScreenState extends ConsumerState<BossDayScreen> {
  final _reviewController = TextEditingController();
  final _futureSelfController = TextEditingController();
  final _perkController = TextEditingController();

  bool _hasBossQuest = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final startOfWeek = widget.date.subtract(Duration(days: widget.date.weekday % 7));
    final endOfWeek = widget.date;

    final hasBoss = await ref.read(questsRepositoryProvider).hasCompletedBossQuestInRange(
          userId,
          startOfWeek,
          endOfWeek,
        );

    final bossDay = await ref.read(bossRepositoryProvider).getBossDayForDate(userId, widget.date);

    if (mounted) {
      setState(() {
        _hasBossQuest = hasBoss;
        if (bossDay != null) {
          _reviewController.text = bossDay.reviewNotes;
          _futureSelfController.text = bossDay.futureSelfNote;
          _perkController.text = bossDay.perkUnlocked ?? '';
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _futureSelfController.dispose();
    _perkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: OperatorPalette.voidBlack,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: Text('Boss Day — ${DateFormat('EEE, MMM d').format(widget.date)}'),
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
              label: 'WEEKLY RAID REVIEW',
              title: 'Enter the Council Hall.',
              body: 'Boss Day is not for guilt. It is for truth. Review the week, name the leak, and choose the next strategic correction.',
              icon: Icons.military_tech_outlined,
              accentColor: OperatorPalette.parchmentGold,
            ),
            const SizedBox(height: 16),
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _ReviewField(
              controller: _reviewController,
              label: 'Weekly Review Notes',
              hint: 'What happened this week? Wins, misses, patterns, leaks.',
              maxLines: 5,
              icon: Icons.fact_check_outlined,
            ),
            const SizedBox(height: 16),
            _ReviewField(
              controller: _futureSelfController,
              label: 'Future Self Note',
              hint: 'What does future you need to remember about this week?',
              maxLines: 3,
              icon: Icons.forum_outlined,
            ),
            const SizedBox(height: 16),
            _buildPerkField(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: userId == null ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Seal Boss Day Review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _hasBossQuest ? OperatorPalette.successGreen : OperatorPalette.warningAmber;
    return OperatorCard(
      label: _hasBossQuest ? 'PERK UNLOCKED' : 'BOSS QUEST MISSING',
      title: _hasBossQuest ? 'Boss-tier mission completed.' : 'No boss-tier mission completed.',
      body: _hasBossQuest
          ? 'The Council recognizes a major win this week. Name the perk and lock in the lesson.'
          : 'Complete one boss-tier mission in a week to unlock a perk. For now, review honestly and choose the correction.',
      icon: _hasBossQuest ? Icons.check_circle_outline : Icons.warning_amber_outlined,
      accentColor: color,
    );
  }

  Widget _buildPerkField() {
    return OperatorCard(
      label: 'PERK RECORD',
      title: _hasBossQuest ? 'Name the unlocked perk.' : 'Perk locked.',
      icon: Icons.workspace_premium_outlined,
      accentColor: _hasBossQuest ? OperatorPalette.successGreen : OperatorPalette.textMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERK RECORD', style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text(_hasBossQuest ? 'Name the unlocked perk.' : 'Perk locked.', style: OperatorTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: _perkController,
            enabled: _hasBossQuest,
            decoration: InputDecoration(
              labelText: 'Perk Unlocked',
              hintText: _hasBossQuest ? 'Name your perk...' : 'Complete a boss mission first',
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref.read(bossRepositoryProvider).saveBossDay(
      userId: userId,
      date: widget.date,
      reviewNotes: _reviewController.text.trim(),
      futureSelfNote: _futureSelfController.text.trim(),
      perkUnlocked: _hasBossQuest ? _perkController.text.trim() : null,
    );

    await refreshMemoryArchive(ref);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: OperatorPalette.panelRaised,
          content: Text('Boss Day sealed. The Council Hall remembers.'),
        ),
      );
    }
  }
}

class _ReviewField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final IconData icon;

  const _ReviewField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OperatorCard(
      label: label.toUpperCase(),
      title: label,
      icon: icon,
      accentColor: OperatorPalette.hologramBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          Text(label, style: OperatorTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: OperatorPalette.panelDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }
}
