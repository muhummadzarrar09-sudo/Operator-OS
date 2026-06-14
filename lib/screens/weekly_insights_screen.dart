import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/services/rag_service.dart';

class WeeklyInsightsScreen extends ConsumerStatefulWidget {
  const WeeklyInsightsScreen({super.key});

  @override
  ConsumerState<WeeklyInsightsScreen> createState() => _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends ConsumerState<WeeklyInsightsScreen> {
  bool _loading = false;
  String? _insight;

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _loading = true;
      _insight = null;
    });

    try {
      final rag = ref.read(ragServiceProvider);
      final ai = ref.read(aiServiceProvider);

      // Retrieve entries from the past 7 days as context.
      final context = await rag.buildContext(
        userId,
        'weekly review summary wins lessons sleep habits',
        k: 10,
      );

      final prompt = '''You are a compassionate performance coach reviewing the user's week.
Use the context below to write a concise, actionable weekly insight (3-5 bullet points).
Be encouraging. Reference specific wins, sleep patterns, and habits if present.

Context:
$context

Weekly Insight:''';

      final response = await ai.generateText(prompt, maxTokens: 512);
      setState(() => _insight = response ?? 'No response from AI model.');
    } catch (e) {
      setState(() => _insight = 'Error generating insight: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekLabel = DateFormat('MMM d').format(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    final todayLabel = DateFormat('MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Insights ($weekLabel – $todayLabel)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generate Weekly Insight'),
            ),
            const SizedBox(height: 16),
            if (_insight != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _insight!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
