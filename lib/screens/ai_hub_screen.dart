import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/screens/future_self_chat_screen.dart';
import 'package:operator_os/screens/weekly_insights_screen.dart';
import 'package:operator_os/services/ai_service.dart';

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
      _status = 'Populating entries...';
    });

    final populator = ref.read(entryPopulationServiceProvider);
    final populated = await populator.populateAll(userId);

    setState(() => _status = 'Embedding $populated entries...');

    final embedder = ref.read(embeddingServiceProvider);
    final embedded = await embedder.embedAllUnembedded(userId);

    setState(() {
      _indexing = false;
      _status = 'Done: $populated entries populated, $embedded embedded.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.read(aiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AiStatusCard(ai: ai),
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
              label: const Text('Index Data for AI'),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _status,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.insights,
              title: 'Weekly Insights',
              subtitle: 'AI-generated recap of your week.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeeklyInsightsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.chat_bubble_outline,
              title: 'Future Self Chat',
              subtitle: 'Ask your future self anything.',
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

class _AiStatusCard extends StatelessWidget {
  final AiService ai;

  const _AiStatusCard({required this.ai});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ai.initialize(),
      builder: (context, snap) {
        final ready = snap.data ?? false;
        return Card(
          color: ready ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  ready ? Icons.check_circle : Icons.info_outline,
                  color: ready ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ready
                        ? 'AI model ready. You can generate embeddings and insights.'
                        : 'AI model not available. Running in mock mode for development.',
                    style: TextStyle(
                      color: ready ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
