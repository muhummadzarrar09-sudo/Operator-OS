import 'package:drift/drift.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'roadmap_repository.g.dart';

@riverpod
RoadmapRepository roadmapRepository(Ref ref) {
  return RoadmapRepository(ref.watch(appDatabaseProvider));
}

class RoadmapRepository {
  final AppDatabase _db;

  RoadmapRepository(this._db);

  static const int _initialDays = 60;
  static const int _extendThresholdDays = 7;
  static const int _extendBatchDays = 60;

  /// Generates or extends roadmap days until the current date is covered
  /// with at least [_extendThresholdDays] of buffer ahead.
  Future<void> ensureDaysGenerated(String userId, DateTime installDate) async {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedInstall = DateTime(installDate.year, installDate.month, installDate.day);

    while (true) {
      final lastExisting = await (_db.select(_db.roadmapDaysTable)
            ..where((r) => r.userId.equals(userId))
            ..orderBy([(r) => OrderingTerm.desc(r.date)])
            ..limit(1))
          .getSingleOrNull();

      if (lastExisting == null) {
        // First time: generate initial batch from install date.
        await _generateDays(userId, normalizedInstall, 1, _initialDays);
        continue; // re-evaluate whether we need more
      }

      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastExisting.date);
      final daysCoverage = lastDate.difference(normalizedNow).inDays;

      if (daysCoverage >= _extendThresholdDays) {
        break; // sufficient coverage
      }

      // Extend by another batch.
      final startDate = lastDate.add(const Duration(days: 1));
      final startDayNumber = lastExisting.dayNumber + 1;
      await _generateDays(userId, startDate, startDayNumber, _extendBatchDays);
    }
  }

  Future<void> _generateDays(
    String userId,
    DateTime startDate,
    int startDayNumber,
    int count,
  ) async {
    // Count existing weekday days to continue the rotation counter `c`.
    final existingDays = await (_db.select(_db.roadmapDaysTable)
          ..where((r) => r.userId.equals(userId)))
        .get();
    int c = existingDays.where((d) => d.dayType == DayType.weekday.name).length;

    await _db.transaction(() async {
      for (int i = 0; i < count; i++) {
        final date = startDate.add(Duration(days: i));
        final dayNumber = startDayNumber + i;
        final isSunday = date.weekday == DateTime.sunday;

        final dayType = isSunday ? DayType.sundayBoss.name : DayType.weekday.name;

        String slotA;
        String slotB;
        String bedtimeTarget;

        if (isSunday) {
          slotA = 'boss_day_free_roam';
          slotB = 'boss_day_free_roam';
          bedtimeTarget = 'Flex - short night';
        } else {
          c++;
          final pos = ((c - 1) % 6) + 1;
          final slots = _slotForPos(pos);
          slotA = slots.$1;
          slotB = slots.$2;
          bedtimeTarget = _bedtimeForDayNumber(dayNumber);
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        await _db.into(_db.roadmapDaysTable).insert(
              RoadmapDaysTableCompanion(
                id: Value(Uuid().v4()),
                userId: Value(userId),
                dayNumber: Value(dayNumber),
                date: Value(date.millisecondsSinceEpoch),
                dayType: Value(dayType),
                slotA: Value(slotA),
                slotB: Value(slotB),
                bedtimeTarget: Value(bedtimeTarget),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  (String, String) _slotForPos(int pos) {
    return switch (pos) {
      1 => ('leverage', 'craft'),
      2 => ('capital', 'leverage'),
      3 => ('craft', 'capital'),
      4 => ('leverage', 'craft'),
      5 => ('capital', 'leverage'),
      6 => ('craft', 'capital'),
      _ => ('leverage', 'craft'),
    };
  }

  String _bedtimeForDayNumber(int dayNumber) {
    if (dayNumber <= 14) return '10:45 PM';
    if (dayNumber <= 21) return '10:30 PM';
    if (dayNumber <= 28) return '10:15 PM';
    // Day 29+: 10:00 PM, then -15min every 14 days.
    final blocks = (dayNumber - 29) ~/ 14;
    final totalMinutes = 22 * 60 - 15 * blocks; // 22:00 = 10:00 PM
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Stream<List<RoadmapDay>> watchDays(String userId) {
    return (_db.select(_db.roadmapDaysTable)
          ..where((r) => r.userId.equals(userId))
          ..orderBy([(r) => OrderingTerm.asc(r.date)]))
        .watch();
  }

  Stream<RoadmapDay?> watchDay(String userId, String dayId) {
    return (_db.select(_db.roadmapDaysTable)
          ..where((r) => r.userId.equals(userId) & r.id.equals(dayId)))
        .watchSingleOrNull();
  }

  Future<RoadmapDay?> getDayByDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    return (_db.select(_db.roadmapDaysTable)
          ..where(
            (r) =>
                r.userId.equals(userId) &
                r.date.isBiggerOrEqualValue(start) &
                r.date.isSmallerOrEqualValue(end),
          ))
        .getSingleOrNull();
  }

  Future<void> markDayDone(String dayId, bool done) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.roadmapDaysTable)
          ..where((r) => r.id.equals(dayId)))
        .write(
      RoadmapDaysTableCompanion(
        done: Value(done),
        updatedAt: Value(now),
      ),
    );
  }
}
