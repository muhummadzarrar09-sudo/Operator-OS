import 'ai_service.dart';
import 'mock_ai_service.dart';

/// Real Gemma integration deferred until model file is available.
/// Delegates entirely to MockAiService for the test build.
/// Re-wire with flutter_gemma once the .bin weights are downloaded.
class GemmaAiService implements AiService {
  final AiService _delegate = MockAiService();

  @override
  Future<bool> initialize() => _delegate.initialize();

  @override
  Future<List<double>?> generateEmbedding(String text) =>
      _delegate.generateEmbedding(text);

  @override
  Future<String?> generateText(String prompt, {int maxTokens = 512}) =>
      _delegate.generateText(prompt, maxTokens: maxTokens);

  @override
  Future<void> dispose() => _delegate.dispose();
}