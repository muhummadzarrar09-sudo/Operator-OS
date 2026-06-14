import 'package:drift/drift.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:operator_os/data/repositories/roadmap_repository.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'sleep_repository.g.dart';

@riverpod
SleepRepository sleepRepository(Ref ref) {
  return SleepRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(statsRepositoryProvider),
    ref.watch(roadmapRepositoryProvider),
  );
}

class SleepRepository {
  final AppDatabase _db;
  final StatsRepository _statsRepo;
  final RoadmapRepository _roadmapRepo;

  SleepRepository(this._db, this._statsRepo, this._roadmapRepo);

  Future<void> createSleepLog({
    required String userId,
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
  }) async {
    final durationMs = wakeTime.difference(bedtime).inMilliseconds;
    var durationHours = durationMs / (1000 * 60 * 60);
    if (durationHours < 0) durationHours += 24;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateMs = normalizedDate.millisecondsSinceEpoch;

    final roadmapDay = await _roadmapRepo.getDayByDate(userId, normalizedDate);
    bool onTarget = false;
    if (roadmapDay != null && roadmapDay.bedtimeTarget != 'Flex - short night') {
      final targetMinutes = _parseBedtime(roadmapDay.bedtimeTarget);
      final bedtimeMinutes = bedtime.hour * 60 + bedtime.minute;
      onTarget = bedtimeMinutes <= targetMinutes + 30;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.sleepLogsTable).insert(
          SleepLogsTableCompanion(
            id: Value(Uuid().v4()),
            userId: Value(userId),
            date: Value(dateMs),
            bedtime: Value(bedtime.millisecondsSinceEpoch),
            wakeTime: Value(wakeTime.millisecondsSinceEpoch),
            durationHours: Value(durationHours),
            onTarget: Value(onTarget),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    if (onTarget) {
      await _statsRepo.addXp(userId, 'vitality', XpConfig.xpRecovery);
    }
  }

  Stream<List<SleepLog>> watchSleepLogs(String userId) {
    return (_db.select(_db.sleepLogsTable)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  int _parseBedtime(String target) {
    // Parse strings like "10:45 PM" or "09:45 PM" into minutes from midnight.
    final parts = target.split(' ');
    if (parts.length != 2) return 22 * 60; // fallback 10:00 PM
    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return 22 * 60;
    var hour = int.tryParse(timeParts[0]) ?? 22;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final period = parts[1].toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }
}
