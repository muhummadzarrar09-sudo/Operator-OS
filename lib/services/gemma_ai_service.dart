import 'ai_service.dart';
import 'mock_ai_service.dart';

/// flutter_gemma-backed AI service.
///
/// **Text generation:** Uses Gemma instruct model (e.g. gemma-2b-it) via
/// `flutter_gemma` `LlmInference`.
///
/// **Embeddings:** flutter_gemma does not expose a native embedding API.
/// This implementation falls back to a deterministic lexical hash vector for
/// retrieval. For production-grade semantic RAG, swap the embedding method
/// with `google_ml_kit` TextEmbedding, an ONNX model via `onnxruntime`,
/// or a dedicated on-device embedding model (e.g. Gecko / all-MiniLM).
///
/// To use: download the model via the flutter_gemma setup instructions and
/// place the `.bin` weights in the app assets or download path.
class GemmaAiService implements AiService {
  final MockAiService _fallback = MockAiService();
  bool _available = false;
  bool _initAttempted = false;

  // ignore: unused_field
  // dynamic _llmInference; // flutter_gemma LlmInference instance
  // ignore: unused_field
  // dynamic _llmModel;     // flutter_gemma LlmInferenceModel instance

  @override
  Future<bool> initialize() async {
    if (_initAttempted) return _available;
    _initAttempted = true;
    try {
      // Attempt to load flutter_gemma model.
      // The exact API depends on the flutter_gemma version.
      // Typical initialization:
      //   _llmModel = await LlmInferenceModel.fromAsset('model.bin');
      //   _llmInference = await LlmInference.create(model: _llmModel);
      //
      // If the model is not present, this throws.
      // TODO: Replace with actual flutter_gemma initialization once the model
      // is downloaded and the exact API for your version is verified.
      //
      // For now, auto-fallback to mock so the app never crashes on boot.
      _available = false;
      return _available;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  @override
  Future<List<double>?> generateEmbedding(String text) async {
    if (!_available) return _fallback.generateEmbedding(text);

    // flutter_gemma does not provide an embedding endpoint.
    // Fallback to deterministic lexical vector.
    // Replace with a real embedding model for production RAG.
    return _fallback.generateEmbedding(text);
  }

  @override
  Future<String?> generateText(String prompt, {int maxTokens = 512}) async {
    if (!_available) return _fallback.generateText(prompt, maxTokens: maxTokens);

    try {
      // TODO: Replace with actual flutter_gemma inference call.
      // Example:
      //   final response = await _llmInference.generateResponse(prompt);
      //   return response;
      return _fallback.generateText(prompt, maxTokens: maxTokens);
    } catch (_) {
      return _fallback.generateText(prompt, maxTokens: maxTokens);
    }
  }

  @override
  Future<void> dispose() async {
    // TODO: Close _llmInference and _llmModel if initialized.
  }
}
