import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';

final todayJournalEntryProvider = FutureProvider<JournalEntry?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(journalRepositoryProvider).getEntryForDate(userId, DateTime.now());
});

final journalHistoryProvider = StreamProvider<List<JournalEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.read(journalRepositoryProvider).watchEntries(userId);
});
