import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/services/ai_service.dart';
import 'package:operator_os/services/mock_ai_service.dart';
import 'package:operator_os/services/rag_service.dart';

void main() {
  group('RagService', () {
    test('retrieve returns top-K entries by embedding similarity', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final ai = MockAiService();
      final rag = RagService(db, ai);

      final vector = (await ai.generateEmbedding('test'))!;
      final blob = _vectorToBlob(vector);

      await db.into(db.entriesTable).insert(
        EntriesTableCompanion(
          id: const Value('e1'),
          userId: const Value('user-1'),
          domain: const Value('forge'),
          entryType: const Value('quest'),
          title: const Value('Test'),
          body: const Value('test'),
          contentHash: const Value('hash1'),
          createdAt: const Value(0),
          updatedAt: const Value(0),
          embedding: Value(blob),
          embeddingDim: Value(vector.length),
          embeddedAt: const Value(0),
        ),
      );

      final results = await rag.retrieve('user-1', 'test', k: 1);
      expect(results.length, 1);
      expect(results.first.id, 'e1');
    });

    test('retrieve falls back to recency when AI embeddings are null', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final rag = RagService(db, _FailingAiService());

      // Fallback path requires embedding.isNotNull(), so insert with null.
      await db.into(db.entriesTable).insert(
        EntriesTableCompanion(
          id: const Value('e1'),
          userId: const Value('user-1'),
          domain: const Value('forge'),
          entryType: const Value('quest'),
          title: const Value('Old'),
          body: const Value('old'),
          contentHash: const Value('hash1'),
          createdAt: const Value(0),
          updatedAt: const Value(0),
          embedding: const Value.absent(),
        ),
      );

      final results = await rag.retrieve('user-1', 'query', k: 1);
      expect(results, isEmpty);
    });
  });
}

class _FailingAiService implements AiService {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<List<double>?> generateEmbedding(String text) async => null;

  @override
  Future<String?> generateText(String prompt, {int maxTokens = 512}) async => null;

  @override
  Future<void> dispose() async {}
}

Uint8List _vectorToBlob(List<double> vector) {
  final floatList = Float32List.fromList(vector);
  return floatList.buffer.asUint8List();
}
