import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/boss_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';

final bossDayForDateProvider =
    FutureProvider.family<BossDay?, DateTime>((ref, date) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(bossRepositoryProvider).getBossDayForDate(userId, date);
});
