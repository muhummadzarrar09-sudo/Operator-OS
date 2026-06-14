import 'dart:math';
import 'dart:typed_data';

import 'ai_service.dart';

/// Mock AI service for testing and development fallback.
/// Embeddings are deterministic hash-based vectors (not semantic, but stable).
/// Text generation returns canned responses.
class MockAiService implements AiService {
  static const int _embeddingDim = 768;
  final Random _random = Random(42);
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
    if (lower.contains('weekly') || lower.contains('summary')) {
      return 'You had a solid week. Focus on consistency in your morning routine. Your wins in FORGE and CLARITY are compounding.';
    }
    if (lower.contains('future') || lower.contains('yourself')) {
      return 'Your future self says: keep shipping. The small daily wins are what build the compound. Don\'t break the streak.';
    }
    if (lower.contains('sleep') || lower.contains('rest')) {
      return 'Recovery is production. Your VITALITY stat grows when you protect sleep. Consider an earlier bedtime this week.';
    }
    return 'I see your progress. Keep the momentum going and stay aligned with your roadmap.';
  }

  @override
  Future<void> dispose() async {}
}
