import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/widgets/operator_card.dart';

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
        'weekly review summary wins lessons sleep habits boss council',
        k: 10,
      );

      final prompt = '''You are the Operator OS War Council reviewing the user's week.
Use the context below to write a concise, actionable Boss Council Report (3-5 bullet points).
Be direct, useful, and encouraging. Reference specific wins, sleep patterns, and habits if present.
End with one clear next move.

Context:
$context

Boss Council Report:''';

      final response = await ai.generateText(prompt, maxTokens: 512);
      setState(() => _insight = response ?? 'No response from the War Council.');
    } catch (e) {
      setState(() => _insight = 'Error generating Council report: $e');
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
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: Text('Boss Council ($weekLabel – $todayLabel)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OperatorCard(
              label: 'BOSS COUNCIL REPORT',
              title: 'Review the week honestly.',
              body: 'The Council will inspect recent memories and return a concise strategic report.',
              icon: Icons.military_tech_outlined,
              accentColor: OperatorPalette.parchmentGold,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generate Council Report'),
            ),
            const SizedBox(height: 16),
            if (_insight != null)
              Expanded(
                child: SingleChildScrollView(
                  child: OperatorCard(
                    label: 'COUNCIL FINDINGS',
                    body: _insight!,
                    icon: Icons.insights,
                    accentColor: OperatorPalette.hologramBlue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
