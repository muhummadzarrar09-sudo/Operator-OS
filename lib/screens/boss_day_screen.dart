import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/data/repositories/boss_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/utils/sign_out_redirect.dart';

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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Boss Day — ${DateFormat('EEE, MMM d').format(widget.date)}'),
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
            _buildStatusBanner(),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Weekly Review Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _futureSelfController,
              decoration: const InputDecoration(
                labelText: 'Future Self Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildPerkField(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: userId == null ? null : _save,
              child: const Text('Save Boss Day'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Card(
      color: _hasBossQuest ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _hasBossQuest ? Icons.check_circle : Icons.warning,
              color: _hasBossQuest ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _hasBossQuest
                    ? 'Boss-tier quest completed this week. Perk unlocked!'
                    : 'No boss-tier quest completed this week. Complete one to unlock a perk.',
                style: TextStyle(
                  color: _hasBossQuest ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkField() {
    return TextField(
      controller: _perkController,
      enabled: _hasBossQuest,
      decoration: InputDecoration(
        labelText: 'Perk Unlocked',
        border: const OutlineInputBorder(),
        hintText: _hasBossQuest ? 'Name your perk...' : 'Complete a boss quest first',
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boss day saved.')),
      );
    }
  }
}
