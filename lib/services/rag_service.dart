import 'dart:math';

import 'package:drift/drift.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/services/ai_service.dart';
import 'package:operator_os/services/embedding_service.dart';

/// Retrieval-Augmented Generation service.
/// Retrieves top-K relevant entries via cosine similarity over embeddings.
class RagService {
  final AppDatabase _db;
  final AiService _ai;

  RagService(this._db, this._ai);

  /// Retrieve the top `k` entries relevant to the query text.
  /// If the AI model is not available, falls back to recency-based retrieval
  /// (last 30 entries).
  Future<List<Entry>> retrieve(String userId, String query, {int k = 5}) async {
    final queryVector = await _ai.generateEmbedding(query);
    if (queryVector == null) {
      // Model unavailable: fallback to recency.
      return (_db.select(_db.entriesTable)
            ..where(
              (e) => e.userId.equals(userId) & e.embedding.isNotNull(),
            )
            ..orderBy([(e) => OrderingTerm.desc(e.updatedAt)])
            ..limit(k))
          .get();
    }

    final all = await (_db.select(_db.entriesTable)
          ..where(
            (e) => e.userId.equals(userId) & e.embedding.isNotNull(),
          ))
        .get();

    final scored = all.map((entry) {
      final vector = EmbeddingService.blobToVector(entry.embedding!);
      final similarity = _cosineSimilarity(queryVector, vector);
      return _ScoredEntry(entry: entry, score: similarity);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).map((s) => s.entry).toList();
  }

  /// Build a context string from retrieved entries for prompt injection.
  Future<String> buildContext(String userId, String query, {int k = 5}) async {
    final entries = await retrieve(userId, query, k: k);
    if (entries.isEmpty) return 'No relevant entries found.';

    return entries
        .map((e) => '[${e.entryType.toUpperCase()} ${e.title}]: ${e.body}')
        .join('\n---\n');
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}

class _ScoredEntry {
  final Entry entry;
  final double score;

  _ScoredEntry({required this.entry, required this.score});
}
