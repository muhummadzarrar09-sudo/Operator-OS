import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_initializer.g.dart';

@riverpod
class UserInitializer extends _$UserInitializer {
  @override
  Future<void> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return;

    final statsRepo = ref.read(statsRepositoryProvider);
    await statsRepo.ensureStatsSeeded(userId);
  }
}
