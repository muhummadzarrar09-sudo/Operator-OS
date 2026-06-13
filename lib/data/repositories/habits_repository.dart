import 'package:drift/drift.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'habits_repository.g.dart';

@riverpod
HabitsRepository habitsRepository(Ref ref) {
  return HabitsRepository(ref.watch(appDatabaseProvider));
}

class HabitsRepository {
  final AppDatabase _db;

  HabitsRepository(this._db);

  Future<void> createHabit({
    required String userId,
    required String domain,
    required String name,
    required String cadence,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.habitsTable).insert(
          HabitsTableCompanion(
            id: Value(Uuid().v4()),
            userId: Value(userId),
            domain: Value(domain),
            name: Value(name),
            cadence: Value(cadence),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<List<Habit>> getHabitsByDomain(String userId, String domain) async {
    return (_db.select(_db.habitsTable)
          ..where((h) => h.userId.equals(userId) & h.domain.equals(domain)))
        .get();
  }

  Future<List<Habit>> getAllHabits(String userId) async {
    return (_db.select(_db.habitsTable)
          ..where((h) => h.userId.equals(userId)))
        .get();
  }

  Future<Habit?> getHabit(String id) async {
    return (_db.select(_db.habitsTable)
          ..where((h) => h.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<Habit>> watchHabitsByDomain(String userId, String domain) {
    return (_db.select(_db.habitsTable)
          ..where((h) => h.userId.equals(userId) & h.domain.equals(domain)))
        .watch();
  }

  /// Completing a habit increments the current streak.
  Future<void> recordHabitCompletion(String habitId) async {
    final habit = await getHabit(habitId);
    if (habit == null) return;

    await (_db.update(_db.habitsTable)..where((h) => h.id.equals(habitId)))
        .write(
      HabitsTableCompanion(
        currentStreak: Value(habit.currentStreak + 1),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Missing a habit decrements skip_tokens_remaining (min 0) and does NOT reset streak or XP.
  Future<void> recordHabitMiss(String habitId) async {
    final habit = await getHabit(habitId);
    if (habit == null) return;

    final newTokens = habit.skipTokensRemaining > 0 ? habit.skipTokensRemaining - 1 : 0;

    await (_db.update(_db.habitsTable)..where((h) => h.id.equals(habitId)))
        .write(
      HabitsTableCompanion(
        skipTokensRemaining: Value(newTokens),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
