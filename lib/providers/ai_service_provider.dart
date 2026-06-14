import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/services/ai_service.dart';
import 'package:operator_os/services/gemma_ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  final service = GemmaAiService();
  // Initialize lazily when first used; dispose on provider teardown.
  ref.onDispose(() async => service.dispose());
  return service;
});
