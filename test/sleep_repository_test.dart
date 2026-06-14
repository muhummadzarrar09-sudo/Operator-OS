import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/roadmap_repository.dart';
import 'package:operator_os/data/repositories/sleep_repository.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';

void main() {
  group('SleepRepository', () {
    test('logs sleep with on_target=true when bedtime is on time', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final statsRepo = StatsRepository(db);
      final roadmapRepo = RoadmapRepository(db);
      final repo = SleepRepository(db, statsRepo, roadmapRepo);

      await statsRepo.ensureStatsSeeded('user-1');
      // Jan 1 2024 is Monday, bedtime target 10:45 PM (22:45 = 1365 min)
      await roadmapRepo.ensureDaysGenerated('user-1', DateTime(2024, 1, 1));

      await repo.createSleepLog(
        userId: 'user-1',
        date: DateTime(2024, 1, 1),
        bedtime: DateTime(2024, 1, 1, 22, 30), // 10:30 PM <= 10:45 PM + 30 grace
        wakeTime: DateTime(2024, 1, 2, 6, 30),
      );

      final logs = await repo.watchSleepLogs('user-1').first;
      expect(logs.length, 1);
      expect(logs.first.onTarget, true);
      expect(logs.first.durationHours, closeTo(8.0, 0.1));

      final stat = await statsRepo.getStat('user-1', 'vitality');
      expect(stat!.currentXp, 25); // Recovery XP awarded
    });

    test('logs sleep with on_target=false when bedtime is late', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final statsRepo = StatsRepository(db);
      final roadmapRepo = RoadmapRepository(db);
      final repo = SleepRepository(db, statsRepo, roadmapRepo);

      await statsRepo.ensureStatsSeeded('user-1');
      await roadmapRepo.ensureDaysGenerated('user-1', DateTime(2024, 1, 1));

      await repo.createSleepLog(
        userId: 'user-1',
        date: DateTime(2024, 1, 1),
        bedtime: DateTime(2024, 1, 1, 23, 30), // 11:30 PM > 10:45 PM + 30 grace
        wakeTime: DateTime(2024, 1, 2, 6, 30),
      );

      final logs = await repo.watchSleepLogs('user-1').first;
      expect(logs.first.onTarget, false);

      final stat = await statsRepo.getStat('user-1', 'vitality');
      expect(stat!.currentXp, 0); // No XP awarded
    });

    test('stream returns logs ordered by date desc', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final statsRepo = StatsRepository(db);
      final roadmapRepo = RoadmapRepository(db);
      final repo = SleepRepository(db, statsRepo, roadmapRepo);

      await statsRepo.ensureStatsSeeded('user-1');
      await roadmapRepo.ensureDaysGenerated('user-1', DateTime(2024, 1, 1));

      await repo.createSleepLog(
        userId: 'user-1',
        date: DateTime(2024, 1, 1),
        bedtime: DateTime(2024, 1, 1, 23, 0),
        wakeTime: DateTime(2024, 1, 2, 6, 0),
      );
      await repo.createSleepLog(
        userId: 'user-1',
        date: DateTime(2024, 1, 2),
        bedtime: DateTime(2024, 1, 2, 23, 0),
        wakeTime: DateTime(2024, 1, 3, 6, 0),
      );

      final logs = await repo.watchSleepLogs('user-1').first;
      expect(logs.length, 2);
      expect(DateTime.fromMillisecondsSinceEpoch(logs[0].date).day, 2);
      expect(DateTime.fromMillisecondsSinceEpoch(logs[1].date).day, 1);
    });
  });
}
