import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/roadmap_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/install_date_provider.dart';

part 'roadmap_provider.g.dart';

@riverpod
class RoadmapInitializer extends _$RoadmapInitializer {
  @override
  Future<void> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;
    final installDate = await ref.read(installDateProvider.future);
    await ref.read(roadmapRepositoryProvider).ensureDaysGenerated(userId, installDate);
  }
}

final roadmapDaysProvider = StreamProvider<List<RoadmapDay>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.read(roadmapRepositoryProvider).watchDays(userId);
});

final roadmapDayProvider = StreamProvider.family<RoadmapDay?, String>((ref, dayId) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.read(roadmapRepositoryProvider).watchDay(userId, dayId);
});
