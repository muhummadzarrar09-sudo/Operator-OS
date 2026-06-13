import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';

void main() {
  late AppDatabase db;
  late StatsRepository repo;

  setUp(() {
    db = AppDatabase.custom(NativeDatabase.memory());
    repo = StatsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('StatsRepository', () {
    test('seeds all 8 stats on first login', () async {
      await repo.ensureStatsSeeded('user-1');
      final stats = await repo.getAllStats('user-1');
      expect(stats.length, 8);
      for (final stat in stats) {
        expect(stat.level, 1);
        expect(stat.currentXp, 0);
      }
      expect(
        stats.map((s) => s.statKey).toSet(),
        StatKey.values.map((k) => k.name).toSet(),
      );
    });

    test('does not duplicate stats on second seed', () async {
      await repo.ensureStatsSeeded('user-1');
      await repo.ensureStatsSeeded('user-1');
      final stats = await repo.getAllStats('user-1');
      expect(stats.length, 8);
    });

    test('awards XP and recalculates level to 2', () async {
      await repo.ensureStatsSeeded('user-1');
      await repo.addXp('user-1', 'forge', 250);
      final stat = await repo.getStat('user-1', 'forge');
      expect(stat!.currentXp, 250);
      expect(stat.level, 2); // 200 XP needed for L2
    });

    test('level up to 3', () async {
      await repo.ensureStatsSeeded('user-1');
      await repo.addXp('user-1', 'forge', 450);
      final stat = await repo.getStat('user-1', 'forge');
      expect(stat!.level, 3);
    });

    test('level up to 4', () async {
      await repo.ensureStatsSeeded('user-1');
      await repo.addXp('user-1', 'forge', 800);
      final stat = await repo.getStat('user-1', 'forge');
      expect(stat!.level, 4);
    });

    test('stream emits seeded stats', () async {
      await repo.ensureStatsSeeded('user-1');
      final stream = repo.watchAllStats('user-1');
      await expectLater(
        stream,
        emits(
          predicate<List<Stat>>(
            (stats) => stats.length == 8 && stats.every((s) => s.level == 1),
          ),
        ),
      );
    });

    test('stream reflects XP update within one emission', () async {
      await repo.ensureStatsSeeded('user-1');
      final stream = repo.watchAllStats('user-1');

      // First emission: seeded stats
      await expectLater(
        stream,
        emits(
          predicate<List<Stat>>(
            (stats) => stats.firstWhere((s) => s.statKey == 'forge').currentXp == 0,
          ),
        ),
      );

      await repo.addXp('user-1', 'forge', 250);

      // Next emission: updated XP
      await expectLater(
        stream,
        emits(
          predicate<List<Stat>>(
            (stats) {
              final forge = stats.firstWhere((s) => s.statKey == 'forge');
              return forge.currentXp == 250 && forge.level == 2;
            },
          ),
        ),
      );
    });
  });
}
