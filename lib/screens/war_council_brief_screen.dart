import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/widgets/operator_card.dart';

class WarCouncilBriefScreen extends ConsumerStatefulWidget {
  const WarCouncilBriefScreen({super.key});

  @override
  ConsumerState<WarCouncilBriefScreen> createState() => _WarCouncilBriefScreenState();
}

class _WarCouncilBriefScreenState extends ConsumerState<WarCouncilBriefScreen> {
  bool _loading = false;
  String? _brief;
  _BriefMode _mode = _BriefMode.morning;

  Future<void> _generate(_BriefMode mode) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _loading = true;
      _brief = null;
      _mode = mode;
    });

    try {
      final rag = ref.read(ragServiceProvider);
      final ai = ref.read(aiServiceProvider);
      final memoryContext = await rag.buildContext(userId, mode.query, k: 10);
      final prompt = _buildPrompt(mode, memoryContext);
      final response = await ai.generateText(prompt, maxTokens: 650);
      setState(() {
        _brief = response ?? 'The Council is quiet right now. Complete one mission and refresh the Memory Archive.';
      });
    } catch (e) {
      setState(() => _brief = 'Council error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildPrompt(_BriefMode mode, String memoryContext) {
    return '''You are the Operator OS War Council.
Speak in a concise tactical style. Be direct, specific, and useful.
Use only the available context. If context is thin, say so and give a safe next move.

Mode: ${mode.title}
Purpose: ${mode.purpose}

Memory Context:
$memoryContext

Return this structure:
1. SITUATION — what you see
2. DIRECTIVE — today's or this moment's priority
3. MISSIONS — 1 to 3 concrete actions
4. RISK — what could derail the Operator
5. COUNCIL NOTE — one sharp final line

War Council Brief:''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(title: const Text('Council Brief')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OperatorCard(
            label: 'WAR COUNCIL BRIEF',
            title: 'Ask the Council for the next move.',
            body: 'The Council reads the Memory Archive and returns a grounded tactical brief. Refresh the archive first for best results.',
            icon: Icons.psychology_alt_outlined,
            accentColor: OperatorPalette.hologramBlue,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _BriefMode.values.map((mode) {
              final selected = mode == _mode;
              return ChoiceChip(
                selected: selected,
                label: Text(mode.shortLabel),
                onSelected: _loading ? null : (_) => _generate(mode),
                selectedColor: OperatorPalette.parchmentGold.withValues(alpha: 0.24),
                labelStyle: TextStyle(
                  color: selected ? OperatorPalette.parchmentGold : OperatorPalette.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : () => _generate(_mode),
            icon: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Consulting Council...' : 'Generate ${_mode.shortLabel}'),
          ),
          const SizedBox(height: 16),
          if (_brief == null && !_loading)
            const OperatorCard(
              label: 'AWAITING COMMAND',
              title: 'Choose a brief type.',
              body: 'Morning Brief sets the day. Tactical Adjustment handles drift. Mission Forge turns fog into action.',
              icon: Icons.bolt_outlined,
              accentColor: OperatorPalette.parchmentGold,
            ),
          if (_brief != null)
            OperatorCard(
              label: _mode.title.toUpperCase(),
              title: 'Council Findings',
              body: _brief!,
              icon: Icons.shield_outlined,
              accentColor: OperatorPalette.parchmentGold,
            ),
        ],
      ),
    );
  }
}

enum _BriefMode {
  morning(
    shortLabel: 'Morning Brief',
    title: 'Morning War Brief',
    purpose: 'Set the day, choose the win condition, and recommend the highest leverage missions.',
    query: 'today morning brief missions quests sleep journal wins lessons roadmap',
  ),
  tactical(
    shortLabel: 'Tactical Adjustment',
    title: 'Tactical Adjustment',
    purpose: 'Detect drift, fatigue, overreach, or neglected stats and recommend an adjustment.',
    query: 'missed quests fatigue sleep low mood behind pace neglected stats adjustment',
  ),
  missionForge(
    shortLabel: 'Mission Forge',
    title: 'Mission Forge',
    purpose: 'Turn vague momentum into 1 to 3 concrete missions the Operator can execute.',
    query: 'goals quests unfinished tasks journal plan tomorrow focus craft forge clarity',
  );

  final String shortLabel;
  final String title;
  final String purpose;
  final String query;

  const _BriefMode({
    required this.shortLabel,
    required this.title,
    required this.purpose,
    required this.query,
  });
}
