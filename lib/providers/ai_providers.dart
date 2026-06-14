import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:operator_os/data/repositories/boss_repository.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/services/embedding_service.dart';
import 'package:operator_os/services/entry_population_service.dart';
import 'package:operator_os/services/rag_service.dart';

final entryPopulationServiceProvider = Provider<EntryPopulationService>((ref) {
  return EntryPopulationService(
    ref.read(appDatabaseProvider),
    ref.read(journalRepositoryProvider),
    ref.read(questsRepositoryProvider),
    ref.read(bossRepositoryProvider),
  );
});

final embeddingServiceProvider = Provider<EmbeddingService>((ref) {
  return EmbeddingService(
    ref.read(appDatabaseProvider),
    ref.read(aiServiceProvider),
  );
});

final ragServiceProvider = Provider<RagService>((ref) {
  return RagService(
    ref.read(appDatabaseProvider),
    ref.read(aiServiceProvider),
  );
});
