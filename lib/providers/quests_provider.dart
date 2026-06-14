import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';

/// See stats_provider.dart for why this is a manual StreamProvider.family
/// rather than @riverpod codegen (Drift row type + riverpod_generator
/// InvalidTypeException in this dependency combo).
final questsByDomainStreamProvider = StreamProvider.family<List<Quest>, String>((ref, domain) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(questsRepositoryProvider).watchPendingQuestsByDomain(userId, domain);
});

final todayQuestsProvider = StreamProvider<List<Quest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;

  return ref
      .watch(questsRepositoryProvider)
      .watchAllPendingQuests(userId)
      .map((quests) => quests.where((q) {
            if (q.dueDate == null) return true;
            return q.dueDate! >= start && q.dueDate! <= end;
          }).toList());
});

final questsByRoadmapDayProvider = StreamProvider.family<List<Quest>, String>((ref, roadmapDayId) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(questsRepositoryProvider).watchQuestsByRoadmapDay(userId, roadmapDayId);
});
