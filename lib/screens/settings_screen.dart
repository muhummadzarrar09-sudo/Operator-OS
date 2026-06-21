import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/user_initializer.dart';
import 'package:operator_os/screens/legal_screen.dart';
import 'package:operator_os/screens/onboarding_screen.dart';
import 'package:operator_os/utils/sign_out_redirect.dart';
import 'package:operator_os/widgets/operator_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _walkthroughComplete;
  bool? _legalAccepted;

  @override
  void initState() {
    super.initState();
    _loadWalkthroughState();
    _loadLegalState();
  }

  Future<void> _loadWalkthroughState() async {
    final complete = await hasCompletedOperatorOnboarding();
    if (!mounted) return;
    setState(() => _walkthroughComplete = complete);
  }

  Future<void> _loadLegalState() async {
    final accepted = await hasAcceptedOperatorLegalTerms();
    if (!mounted) return;
    setState(() => _legalAccepted = accepted);
  }

  Future<void> _setLegalAccepted(bool value) async {
    await setOperatorLegalAccepted(value);
    if (!mounted) return;
    setState(() => _legalAccepted = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Legal acknowledgement saved.' : 'Legal acknowledgement reset.'),
      ),
    );
  }

  Future<void> _setWalkthroughComplete(bool value) async {
    await setOperatorOnboardingComplete(value);
    if (!mounted) return;
    setState(() => _walkthroughComplete = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Walkthrough marked complete.'
              : 'Walkthrough will show after your next sign-in/launch.',
        ),
      ),
    );
  }

  Future<void> _replayWalkthrough() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
    );
    _loadWalkthroughState();
  }

  Future<void> _confirmAndClearLocalData(String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active user to clear.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This deletes local stats, missions, journal entries, roadmap, sleep logs, boss days, and memory entries for the current user on this device. It does not delete remote Supabase data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear local data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      await (db.delete(db.statsTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.questsTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.habitsTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.journalEntriesTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.roadmapDaysTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.sleepLogsTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.bossDaysTable)..where((row) => row.userId.equals(userId))).go();
      await (db.delete(db.entriesTable)..where((row) => row.userId.equals(userId))).go();
    });

    ref.invalidate(userInitializerProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local data cleared for this user.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final isLocalMode = userId == localOperatorUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OperatorPalette.voidBlack,
                    OperatorPalette.nightNavy,
                    Color(0xFF0B111C),
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              OperatorCard(
                icon: Icons.tune_outlined,
                label: 'APP SETTINGS',
                title: 'Keep the system clean.',
                body:
                    'Settings is where you manage onboarding, auth mode, and simple app guidance without cluttering the main nav.',
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Account & Mode',
                children: [
                  _SettingsInfoRow(
                    icon: isLocalMode ? Icons.phone_android : Icons.cloud_done_outlined,
                    color: isLocalMode ? OperatorPalette.parchmentGold : OperatorPalette.hologramBlue,
                    title: isLocalMode ? 'Personal Mode' : 'Online Mode',
                    subtitle: isLocalMode
                        ? 'Your current data is tied to the local operator profile on this device.'
                        : 'Your current data is tied to your Supabase account.',
                  ),
                  _SettingsInfoRow(
                    icon: Icons.badge_outlined,
                    color: OperatorPalette.textMuted,
                    title: 'User ID',
                    subtitle: userId ?? 'No active user',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => signOutAndReturnToLogin(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Walkthrough',
                children: [
                  _SettingsInfoRow(
                    icon: Icons.school_outlined,
                    color: OperatorPalette.successGreen,
                    title: 'Operator Bootcamp',
                    subtitle: _walkthroughComplete == null
                        ? 'Checking walkthrough state...'
                        : _walkthroughComplete!
                            ? 'Completed. You can replay it anytime.'
                            : 'Not completed. It will show on first authenticated launch.',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _replayWalkthrough,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Replay walkthrough'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setWalkthroughComplete(false),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Show on next launch'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setWalkthroughComplete(true),
                          icon: const Icon(Icons.done),
                          label: const Text('Mark done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _SettingsSection(
                title: 'How to read the app',
                children: [
                  _SettingsInfoRow(
                    icon: Icons.dashboard_outlined,
                    color: OperatorPalette.parchmentGold,
                    title: 'Command',
                    subtitle: 'Daily missions, XP snapshot, and quick links to deeper tools.',
                  ),
                  _SettingsInfoRow(
                    icon: Icons.castle_outlined,
                    color: OperatorPalette.torchOrange,
                    title: 'Compound',
                    subtitle: 'Your 8 stats as buildings. Complete missions to upgrade the base.',
                  ),
                  _SettingsInfoRow(
                    icon: Icons.psychology_alt_outlined,
                    color: OperatorPalette.hologramBlue,
                    title: 'AI',
                    subtitle: 'Insights and memory tools. Falls back safely if no local model is configured.',
                  ),
                  _SettingsInfoRow(
                    icon: Icons.settings_outlined,
                    color: OperatorPalette.textMuted,
                    title: 'Settings',
                    subtitle: 'Replay onboarding, inspect mode, and sign out.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Privacy & legal',
                children: [
                  _SettingsInfoRow(
                    icon: Icons.privacy_tip_outlined,
                    color: OperatorPalette.hologramBlue,
                    title: 'Privacy Policy',
                    subtitle: 'Explains local storage, optional Supabase sync, AI data handling, permissions, and deletion notes.',
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: const Text('Open Privacy Policy'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const TermsOfUseScreen()),
                    ),
                    icon: const Icon(Icons.gavel_outlined),
                    label: const Text('Terms & Safety Notes'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const DataSafetyScreen()),
                    ),
                    icon: const Icon(Icons.security_outlined),
                    label: const Text('Data Safety Checklist'),
                  ),
                  const SizedBox(height: 12),
                  _SettingsInfoRow(
                    icon: Icons.verified_user_outlined,
                    color: _legalAccepted == true
                        ? OperatorPalette.successGreen
                        : OperatorPalette.warningAmber,
                    title: 'Legal acknowledgement',
                    subtitle: _legalAccepted == null
                        ? 'Checking acknowledgement state...'
                        : _legalAccepted!
                            ? 'Accepted on this device.'
                            : 'Not accepted yet. Login actions require acknowledgement.',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setLegalAccepted(false),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _setLegalAccepted(true),
                          icon: const Icon(Icons.done),
                          label: const Text('Mark accepted'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SettingsSection(
                title: 'Data controls',
                children: [
                  const _SettingsInfoRow(
                    icon: Icons.storage_outlined,
                    color: OperatorPalette.warningAmber,
                    title: 'Local-first data',
                    subtitle:
                        'Stats, missions, sleep, roadmap, and journal entries live in the local Drift database. Supabase sync is optional/config-dependent.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _confirmAndClearLocalData(userId),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear local data for this user'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For public release, also provide a web privacy policy URL and account/data deletion path if accounts are enabled.',
                    style: OperatorTextStyles.muted,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OperatorPalette.panelDark.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OperatorPalette.borderDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: OperatorTextStyles.overline),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SettingsInfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OperatorPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: OperatorTextStyles.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
