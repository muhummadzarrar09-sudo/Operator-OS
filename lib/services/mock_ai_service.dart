import 'dart:math';

import 'ai_service.dart';

/// Mock AI service for testing and development fallback.
/// Embeddings are deterministic hash-based vectors (not semantic, but stable).
/// Text generation returns canned responses.
class MockAiService implements AiService {
  static const int _embeddingDim = 768;
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = true;
    return true;
  }

  @override
  Future<List<double>?> generateEmbedding(String text) async {
    // Deterministic pseudo-random embedding from text hash.
    final seed = text.hashCode;
    final rng = Random(seed);
    return List.generate(_embeddingDim, (_) => (rng.nextDouble() * 2) - 1);
  }

  @override
  Future<String?> generateText(String prompt, {int maxTokens = 512}) async {
    // Simple canned responses based on prompt keywords.
    final lower = prompt.toLowerCase();
    if (lower.contains('weekly') || lower.contains('summary') || lower.contains('boss council')) {
      return 'Boss Council Report:\n• You had a solid week.\n• Your wins in FORGE and CLARITY are compounding.\n• Protect the morning routine; it is the keystone.\nNext move: choose one mission that strengthens the weakest building.';
    }
    if (lower.contains('future') || lower.contains('yourself')) {
      return 'Your future self says: keep shipping. The small daily wins are what build the compound. Don\'t break the streak. Hard truth: the next level is not hidden — it is waiting behind the mission you keep delaying.';
    }
    if (lower.contains('sleep') || lower.contains('rest')) {
      return 'Recovery is production. Your VITALITY stat grows when you protect sleep. Consider an earlier bedtime this week.';
    }
    if (lower.contains('gemma') || lower.contains('model vault')) {
      return 'Model Vault status: fallback mode is active. Gemma runtime wiring is pending approval, but the Council interface can still generate development briefings.';
    }
    if (lower.contains('campaign map') || lower.contains('campaign council') || lower.contains('roadmap adjustment')) {
      return 'MAP READ — The next stretch of the Campaign Map is readable, but fallback mode has limited memory depth.\n\nADJUSTMENT — Do not rewrite the whole week. Add one recovery or clarity mission if the board feels overloaded.\n\nWHY — Small tactical corrections beat dramatic resets.\n\nMISSION SEED — Add one 25 XP Clarity mission: review the next 24 hours and remove one low-value task.\n\nWARNING — Do not turn planning into avoidance.';
    }
    if (lower.contains('war council') || lower.contains('morning brief') || lower.contains('mission forge') || lower.contains('tactical adjustment')) {
      return 'SITUATION — The Compound is active, but the Memory Archive is still light in fallback mode.\n\nDIRECTIVE — Complete one meaningful mission before the day gets noisy.\n\nMISSIONS — 1) Pick the weakest building. 2) Finish one visible task. 3) Record the lesson after completion.\n\nRISK — Overplanning can disguise avoidance.\n\nCOUNCIL NOTE — One clean mission beats a perfect plan.';
    }
    return 'I see your progress. Keep the momentum going and stay aligned with your Campaign Map.';
  }

  @override
  Future<void> dispose() async {}
}
