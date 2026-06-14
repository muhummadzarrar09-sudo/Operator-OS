import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/services/mock_ai_service.dart';

void main() {
  group('MockAiService', () {
    final ai = MockAiService();

    setUpAll(() async {
      expect(await ai.initialize(), true);
    });

    test('generateEmbedding returns deterministic vector', () async {
      final v1 = await ai.generateEmbedding('hello world');
      final v2 = await ai.generateEmbedding('hello world');
      final v3 = await ai.generateEmbedding('different text');

      expect(v1, isNotNull);
      expect(v1!.length, 768);
      expect(v1, v2);
      expect(v1, isNot(equals(v3)));
    });

    test('generateText returns keyword-matched canned response', () async {
      final weekly = await ai.generateText('weekly summary');
      expect(weekly, contains('week'));

      final future = await ai.generateText('future yourself');
      expect(future, contains('future self'));

      final sleep = await ai.generateText('sleep rest');
      expect(sleep, contains('VITALITY'));
    });
  });
}
