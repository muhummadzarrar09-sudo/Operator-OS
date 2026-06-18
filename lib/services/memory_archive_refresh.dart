import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/auth_provider.dart';

/// Safely refreshes the local Memory Archive after meaningful user actions.
///
/// Additive Phase 15 helper. It uses existing services/providers only:
/// - EntryPopulationService
/// - EmbeddingService
/// - currentUserIdProvider
///
/// It intentionally swallows errors so journaling, Boss Day saves, and mission
/// completion never fail just because the archive refresh did.
Future<void> refreshMemoryArchive(WidgetRef ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return;

  try {
    final populator = ref.read(entryPopulationServiceProvider);
    final embedder = ref.read(embeddingServiceProvider);
    await populator.populateAll(userId);
    await embedder.embedAllUnembedded(userId);
  } catch (e) {
    debugPrint('Memory Archive refresh skipped/failed: $e');
  }
}
