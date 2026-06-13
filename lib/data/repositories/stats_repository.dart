import 'package:drift/drift.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'stats_repository.g.dart';

@riverpod
StatsRepository statsRepository(Ref ref) {
  return StatsRepository(ref.watch(appDatabaseProvider));
}

class StatsRepository {
  final AppDatabase _db;

  StatsRepository(this._db);

  /// Seeds all 8 stats at level 1 / 0 XP for a given user if they don't exist.
  Future<void> ensureStatsSeeded(String userId) async {
    final existing = await (_db.select(_db.statsTable)
          ..where((s) => s.userId.equals(userId)))
        .get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final key in StatKey.values) {
      await _db.into(_db.statsTable).insert(
            StatsTableCompanion(
              id: Value(Uuid().v4()),
              userId: Value(userId),
              statKey: Value(key.name),
              level: const Value(1),
              currentXp: const Value(0),
              subStatsJson: const Value('{}'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Stream<List<Stat>> watchAllStats(String userId) {
    return (_db.select(_db.statsTable)
          ..where((s) => s.userId.equals(userId)))
        .watch();
  }

  Stream<Stat?> watchStatByKey(String userId, String statKey) {
    return (_db.select(_db.statsTable)
          ..where((s) => s.userId.equals(userId) & s.statKey.equals(statKey)))
        .watch()
        .map((rows) => rows.firstOrNull);
  }

  Future<Stat?> getStat(String userId, String statKey) async {
    return (_db.select(_db.statsTable)
          ..where((s) => s.userId.equals(userId) & s.statKey.equals(statKey)))
        .getSingleOrNull();
  }

  Future<List<Stat>> getAllStats(String userId) async {
    return (_db.select(_db.statsTable)
          ..where((s) => s.userId.equals(userId)))
        .get();
  }

  /// Awards XP to a stat, recalculates level, and persists.
  Future<void> addXp(String userId, String statKey, int xp) async {
    final stat = await getStat(userId, statKey);
    if (stat == null) {
      throw Exception('Stat not found for key: $statKey');
    }

    final newXp = stat.currentXp + xp;
    final newLevel = XpConfig.levelForXp(newXp);
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.statsTable)..where((s) => s.id.equals(stat.id)))
        .write(
      StatsTableCompanion(
        currentXp: Value(newXp),
        level: Value(newLevel),
        updatedAt: Value(now),
      ),
    );
  }
}
