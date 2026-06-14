import 'package:drift/drift.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'boss_repository.g.dart';

@riverpod
BossRepository bossRepository(Ref ref) {
  return BossRepository(ref.watch(appDatabaseProvider));
}

class BossRepository {
  final AppDatabase _db;

  BossRepository(this._db);

  Future<BossDay?> getBossDayForDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    return (_db.select(_db.bossDaysTable)
          ..where(
            (b) =>
                b.userId.equals(userId) &
                b.date.isBiggerOrEqualValue(start) &
                b.date.isSmallerOrEqualValue(end),
          ))
        .getSingleOrNull();
  }

  Future<void> saveBossDay({
    required String userId,
    required DateTime date,
    String reviewNotes = '',
    String futureSelfNote = '',
    String? perkUnlocked,
  }) async {
    final existing = await getBossDayForDate(userId, date);
    final now = DateTime.now().millisecondsSinceEpoch;
    final dateMs = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    if (existing == null) {
      await _db.into(_db.bossDaysTable).insert(
            BossDaysTableCompanion(
              id: Value(Uuid().v4()),
              userId: Value(userId),
              date: Value(dateMs),
              reviewNotes: Value(reviewNotes),
              futureSelfNote: Value(futureSelfNote),
              perkUnlocked: Value(perkUnlocked),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.bossDaysTable)..where((b) => b.id.equals(existing.id)))
          .write(
        BossDaysTableCompanion(
          reviewNotes: Value(reviewNotes),
          futureSelfNote: Value(futureSelfNote),
          perkUnlocked: Value(perkUnlocked),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
