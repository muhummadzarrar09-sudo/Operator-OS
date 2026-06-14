import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/services/ai_service.dart';

/// Orchestrates embedding generation for all un-embedded rows in the
/// `entries` table. Embeddings are stored as float32 BLOBs.
class EmbeddingService {
  final AppDatabase _db;
  final AiService _ai;

  EmbeddingService(this._db, this._ai);

  /// Returns the number of embeddings generated in this batch.
  Future<int> embedAllUnembedded(String userId) async {
    final rows = await (_db.select(_db.entriesTable)
          ..where(
            (e) =>
                e.userId.equals(userId) &
                e.embedding.isNull(),
          ))
        .get();

    int count = 0;
    for (final row in rows) {
      final vector = await _ai.generateEmbedding(row.body);
      if (vector == null) continue; // model not ready

      final blob = _vectorToBlob(vector);
      final now = DateTime.now().millisecondsSinceEpoch;

      await (_db.update(_db.entriesTable)..where((e) => e.id.equals(row.id)))
          .write(
        EntriesTableCompanion(
          embedding: Value(blob),
          embeddingModel: const Value('mock-v1'), // TODO: swap with real model name
          embeddingDim: Value(vector.length),
          embeddedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      count++;
    }
    return count;
  }

  Uint8List _vectorToBlob(List<double> vector) {
    final floatList = Float32List.fromList(vector);
    return floatList.buffer.asUint8List();
  }

  static List<double> blobToVector(Uint8List blob) {
    final floatList = Float32List.view(blob.buffer);
    return floatList.toList();
  }
}
