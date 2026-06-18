import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/screens/future_self_chat_screen.dart';
import 'package:operator_os/screens/model_vault_screen.dart';
import 'package:operator_os/screens/war_council_brief_screen.dart';
import 'package:operator_os/screens/weekly_insights_screen.dart';
import 'package:operator_os/services/ai_runtime_status.dart';
import 'package:operator_os/services/ai_service.dart';
import 'package:operator_os/services/gemma_ai_service.dart';
import 'package:operator_os/widgets/operator_card.dart';

class AiHubScreen extends ConsumerStatefulWidget {
  const AiHubScreen({super.key});

  @override
  ConsumerState<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends ConsumerState<AiHubScreen> {
  bool _indexing = false;
  String _status = '';

  Future<void> _indexData() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _indexing = true;
      _status = 'Gathering records for the Memory Archive...';
    });

    final populator = ref.read(entryPopulationServiceProvider);
    final populated = await populator.populateAll(userId);

    setState(() => _status = 'Embedding $populated memory records...');

    final embedder = ref.read(embeddingServiceProvider);
    final embedded = await embedder.embedAllUnembedded(userId);

    setState(() {
      _indexing = false;
      _status = 'Archive refreshed: $populated records gathered, $embedded prepared for Council review.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.read(aiServiceProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: const Text('War Council'),
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
            _CouncilHeader(ai: ai),
            const SizedBox(height: 16),
            OperatorCard(
              label: 'MEMORY ARCHIVE',
              title: 'Refresh records for Council review.',
              body: 'Journal entries, missions, and Boss Day notes become memory records for future briefings.',
              icon: Icons.auto_stories_outlined,
              accentColor: OperatorPalette.hologramBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: OperatorPalette.hologramBlue.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: OperatorPalette.hologramBlue.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_stories_outlined,
                          color: OperatorPalette.hologramBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MEMORY ARCHIVE', style: OperatorTextStyles.overline),
                            SizedBox(height: 6),
                            Text('Prepare records for the Council.', style: OperatorTextStyles.title),
                            SizedBox(height: 8),
                            Text(
                              'Refresh memories before asking for deeper guidance or weekly reports.',
                              style: OperatorTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _indexing ? null : _indexData,
                    icon: _indexing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh Memory Archive'),
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_status, style: OperatorTextStyles.muted),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('COUNCIL CHAMBERS', style: OperatorTextStyles.overline),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.memory_outlined,
              title: 'Model Vault',
              subtitle: 'Inspect Gemma readiness, model file detection, and fallback mode.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ModelVaultScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.psychology_alt_outlined,
              title: 'Council Brief',
              subtitle: 'Generate a Morning Brief, Tactical Adjustment, or Mission Forge plan.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WarCouncilBriefScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.insights,
              title: 'Boss Council Report',
              subtitle: 'Weekly strategic review of progress, leaks, and the next move.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeeklyInsightsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.forum_outlined,
              title: 'Future Self Portal',
              subtitle: 'Ask about decisions, patterns, fears, and high-leverage moves.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FutureSelfChatScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouncilHeader extends StatelessWidget {
  final AiService ai;

  const _CouncilHeader({required this.ai});

  @override
  Widget build(BuildContext context) {
    if (ai is GemmaAiService) {
      return FutureBuilder<AiRuntimeReport>(
        future: (ai as GemmaAiService).runtimeReport(),
        builder: (context, snap) {
          final report = snap.data;
          if (report == null) {
            return const OperatorCard(
              label: 'COUNCIL STATUS',
              title: 'Inspecting Model Vault...',
              body: 'Checking local Gemma readiness while keeping fallback mode safe.',
              icon: Icons.memory_outlined,
              accentColor: OperatorPalette.hologramBlue,
            );
          }
          return OperatorCard(
            label: 'COUNCIL STATUS',
            title: report.status,
            body: '${report.detail}\n\nMode: ${report.mode}\nModel: ${report.modelName}',
            icon: report.hasDetectedModel ? Icons.check_circle_outline : Icons.shield_outlined,
            accentColor: report.hasDetectedModel
                ? OperatorPalette.successGreen
                : OperatorPalette.parchmentGold,
          );
        },
      );
    }

    return FutureBuilder<bool>(
      future: ai.initialize(),
      builder: (context, snap) {
        final online = snap.data ?? false;
        return OperatorCard(
          label: 'COUNCIL STATUS',
          title: online ? 'Council interface online.' : 'Council interface limited.',
          body: online
              ? 'Fallback mode is active in this build. Briefings and memory workflows are available.'
              : 'The War Council is not fully available yet. Memory features may be limited.',
          icon: online ? Icons.shield_outlined : Icons.info_outline,
          accentColor: online ? OperatorPalette.parchmentGold : OperatorPalette.warningAmber,
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OperatorCard(
      icon: icon,
      title: title,
      body: subtitle,
      accentColor: OperatorPalette.parchmentGold,
      trailing: const Icon(Icons.chevron_right, color: OperatorPalette.textSecondary),
      onTap: onTap,
    );
  }
}
