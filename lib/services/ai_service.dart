/// Abstract interface for on-device AI operations.
/// Implementations handle model initialization, text generation, and embeddings.
abstract class AiService {
  /// Initialize the model(s). Returns true if ready.
  Future<bool> initialize();

  /// Generate an embedding vector for a text string.
  /// Returns null if the model is not available or embeddings are unsupported.
  Future<List<double>?> generateEmbedding(String text);

  /// Generate a text response from a prompt.
  /// Returns null if the model is not available.
  Future<String?> generateText(String prompt, {int maxTokens = 512});

  /// Release model resources.
  Future<void> dispose();
}
