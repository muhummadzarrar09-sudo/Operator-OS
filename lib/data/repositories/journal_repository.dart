import 'package:drift/drift.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'journal_repository.g.dart';

@riverpod
JournalRepository journalRepository(Ref ref) {
  return JournalRepository(ref.watch(appDatabaseProvider));
}

class JournalRepository {
  final AppDatabase _db;

  JournalRepository(this._db);

  Future<JournalEntry?> getEntryForDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    return (_db.select(_db.journalEntriesTable)
          ..where(
            (j) =>
                j.userId.equals(userId) &
                j.date.isBiggerOrEqualValue(start) &
                j.date.isSmallerOrEqualValue(end),
          ))
        .getSingleOrNull();
  }

  Stream<List<JournalEntry>> watchEntries(String userId) {
    return (_db.select(_db.journalEntriesTable)
          ..where((j) => j.userId.equals(userId))
          ..orderBy([(j) => OrderingTerm.desc(j.date)]))
        .watch();
  }

  Future<void> saveEntry({
    required String userId,
    required DateTime date,
    required Mood mood,
    double? sleepHours,
    SleepQuality? sleepQuality,
    String wins = '',
    String lessonLearned = '',
    String tomorrowPlan = '',
    String bigPictureNote = '',
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final start = normalizedDate.millisecondsSinceEpoch;
    final existing = await getEntryForDate(userId, date);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing == null) {
      await _db.into(_db.journalEntriesTable).insert(
            JournalEntriesTableCompanion(
              id: Value(Uuid().v4()),
              userId: Value(userId),
              date: Value(start),
              mood: Value(mood.name),
              sleepHours: Value(sleepHours),
              sleepQuality: Value(sleepQuality?.name),
              wins: Value(wins),
              lessonLearned: Value(lessonLearned),
              tomorrowPlan: Value(tomorrowPlan),
              bigPictureNote: Value(bigPictureNote),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.journalEntriesTable)
            ..where((j) => j.id.equals(existing.id)))
          .write(
        JournalEntriesTableCompanion(
          mood: Value(mood.name),
          sleepHours: Value(sleepHours),
          sleepQuality: Value(sleepQuality?.name),
          wins: Value(wins),
          lessonLearned: Value(lessonLearned),
          tomorrowPlan: Value(tomorrowPlan),
          bigPictureNote: Value(bigPictureNote),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
