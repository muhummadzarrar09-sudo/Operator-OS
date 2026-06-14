import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/boss_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';

void main() {
  group('BossRepository', () {
    test('creates and retrieves boss day', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = BossRepository(db);

      final date = DateTime(2024, 1, 7); // Sunday
      await repo.saveBossDay(
        userId: 'user-1',
        date: date,
        reviewNotes: 'Great week',
        futureSelfNote: 'Stay consistent',
        perkUnlocked: 'Early riser',
      );

      final entry = await repo.getBossDayForDate('user-1', date);
      expect(entry, isNotNull);
      expect(entry!.reviewNotes, 'Great week');
      expect(entry.futureSelfNote, 'Stay consistent');
      expect(entry.perkUnlocked, 'Early riser');
    });

    test('updates existing boss day', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = BossRepository(db);

      final date = DateTime(2024, 1, 7);
      await repo.saveBossDay(userId: 'user-1', date: date, reviewNotes: 'A');
      await repo.saveBossDay(userId: 'user-1', date: date, reviewNotes: 'B');

      final entry = await repo.getBossDayForDate('user-1', date);
      expect(entry!.reviewNotes, 'B');
    });
  });

  group('BossQuestCheck', () {
    test('detects completed boss quest in range', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final statsRepo = StatsRepository(db);
      final questsRepo = QuestsRepository(db, statsRepo);

      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Boss fight',
        tier: QuestTier.boss,
      );
      final quests = await questsRepo.getPendingQuestsByDomain('user-1', 'forge');
      await questsRepo.completeQuest('user-1', quests.first.id);

      final hasBoss = await questsRepo.hasCompletedBossQuestInRange(
        'user-1',
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now(),
      );
      expect(hasBoss, true);
    });

    test('returns false when no boss quest completed', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final statsRepo = StatsRepository(db);
      final questsRepo = QuestsRepository(db, statsRepo);

      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Standard quest',
        tier: QuestTier.standard,
      );
      final quests = await questsRepo.getPendingQuestsByDomain('user-1', 'forge');
      await questsRepo.completeQuest('user-1', quests.first.id);

      final hasBoss = await questsRepo.hasCompletedBossQuestInRange(
        'user-1',
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now(),
      );
      expect(hasBoss, false);
    });
  });
}
