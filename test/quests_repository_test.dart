import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';

void main() {
  late AppDatabase db;
  late StatsRepository statsRepo;
  late QuestsRepository questsRepo;

  setUp(() {
    db = AppDatabase.custom(NativeDatabase.memory());
    statsRepo = StatsRepository(db);
    questsRepo = QuestsRepository(db, statsRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('QuestsRepository', () {
    test('completing a quest awards XP to the linked stat', () async {
      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Ship a feature',
        tier: QuestTier.standard,
      );

      final quests = await questsRepo.getPendingQuestsByDomain('user-1', 'forge');
      expect(quests.length, 1);

      await questsRepo.completeQuest('user-1', quests.first.id);

      final stat = await statsRepo.getStat('user-1', 'forge');
      expect(stat!.currentXp, 25); // standard quest = 25 XP
      expect(stat.level, 1); // 25 < 200
    });

    test('completing a hard quest awards 75 XP', () async {
      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'academy',
        title: 'Mock test',
        tier: QuestTier.hard,
      );

      final quests = await questsRepo.getPendingQuestsByDomain('user-1', 'academy');
      await questsRepo.completeQuest('user-1', quests.first.id);

      final stat = await statsRepo.getStat('user-1', 'academy');
      expect(stat!.currentXp, 75);
      expect(stat.level, 1);
    });

    test('completing a boss quest levels up stat to 2', () async {
      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Launch product',
        tier: QuestTier.boss,
      );

      final quests = await questsRepo.getPendingQuestsByDomain('user-1', 'forge');
      await questsRepo.completeQuest('user-1', quests.first.id);

      final stat = await statsRepo.getStat('user-1', 'forge');
      expect(stat!.currentXp, 300); // boss default
      expect(stat.level, 2); // 300 >= 200
    });

    test('completed quest moves from pending to done', () async {
      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'craft',
        title: 'Write blog',
        tier: QuestTier.trivial,
      );

      final pendingBefore = await questsRepo.getPendingQuestsByDomain('user-1', 'craft');
      expect(pendingBefore.length, 1);

      final doneBefore = await questsRepo.getDoneQuestsByDomain('user-1', 'craft');
      expect(doneBefore.length, 0);

      await questsRepo.completeQuest('user-1', pendingBefore.first.id);

      final pendingAfter = await questsRepo.getPendingQuestsByDomain('user-1', 'craft');
      expect(pendingAfter.length, 0);

      final doneAfter = await questsRepo.getDoneQuestsByDomain('user-1', 'craft');
      expect(doneAfter.length, 1);
    });

    test('completing already completed quest throws', () async {
      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Task',
        tier: QuestTier.trivial,
      );

      final quests = await questsRepo.getPendingQuestsByDomain('user-1', 'forge');
      await questsRepo.completeQuest('user-1', quests.first.id);

      await expectLater(
        questsRepo.completeQuest('user-1', quests.first.id),
        throwsA(isA<Exception>()),
      );
    });

    test('stream emits pending quests by domain', () async {
      await statsRepo.ensureStatsSeeded('user-1');
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Stream quest',
        tier: QuestTier.standard,
      );

      final stream = questsRepo.watchPendingQuestsByDomain('user-1', 'forge');
      await expectLater(
        stream,
        emits(
          predicate<List<Quest>>(
            (quests) => quests.length == 1 && quests.first.title == 'Stream quest',
          ),
        ),
      );
    });
  });
}
