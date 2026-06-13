import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';

/// NOTE: deliberately NOT using @riverpod codegen here.
/// riverpod_generator 4.0.4 + drift_dev 2.34.0 (analyzer 12.1.0) cannot
/// generate code for any @riverpod provider whose return type involves a
/// Drift-generated row class (Stat/Quest/Habit, defined via database.g.dart's
/// part directive) when both generators run in the same build_runner pass —
/// confirmed via minimal repro, throws InvalidTypeException regardless of
/// Ref style, family/non-family, or sync/async. Manual StreamProvider /
/// StreamProvider.family sidesteps the cross-generator type resolution issue
/// entirely while keeping the exact same call sites
/// (statsStreamProvider, statByKeyStreamProvider(statKey)).

final statsStreamProvider = StreamProvider<List<Stat>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(statsRepositoryProvider).watchAllStats(userId);
});

final statByKeyStreamProvider = StreamProvider.family<Stat?, String>((ref, statKey) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(statsRepositoryProvider).watchStatByKey(userId, statKey);
});
