import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/sleep_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';

final sleepLogsProvider = StreamProvider<List<SleepLog>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.read(sleepRepositoryProvider).watchSleepLogs(userId);
});
