import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/boss_repository.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/services/entry_population_service.dart';

void main() {
  group('EntryPopulationService', () {
    test('populates entries from journal, quests, and boss days', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());

      final statsRepo = StatsRepository(db);
      final journalRepo = JournalRepository(db);
      final questsRepo = QuestsRepository(db, statsRepo);
      final bossRepo = BossRepository(db);
      final populator = EntryPopulationService(
        db,
        journalRepo,
        questsRepo,
        bossRepo,
      );

      await statsRepo.ensureStatsSeeded('user-1');

      // Journal entry
      await journalRepo.saveEntry(
        userId: 'user-1',
        date: DateTime(2024, 6, 14),
        mood: Mood.great,
        wins: 'Shipped feature',
      );

      // Quest
      await questsRepo.createQuest(
        userId: 'user-1',
        domain: 'forge',
        title: 'Code review',
        tier: QuestTier.standard,
      );

      // Boss day
      await bossRepo.saveBossDay(
        userId: 'user-1',
        date: DateTime(2024, 6, 14),
        reviewNotes: 'Solid week',
        futureSelfNote: 'Keep going',
      );

      final inserted = await populator.populateAll('user-1');
      expect(inserted, greaterThanOrEqualTo(3));

      final entries = await db.select(db.entriesTable).get();
      final userEntries = entries.where((e) => e.userId == 'user-1').toList();
      expect(userEntries.length, 3);

      expect(userEntries.map((e) => e.entryType).toSet(),
          containsAll(['journal', 'quest', 'boss_review']));
    });

    test('deduplicates by content hash', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());

      final journalRepo = JournalRepository(db);
      final populator = EntryPopulationService(
        db,
        journalRepo,
        QuestsRepository(db, StatsRepository(db)),
        BossRepository(db),
      );

      await journalRepo.saveEntry(
        userId: 'user-1',
        date: DateTime(2024, 6, 14),
        mood: Mood.great,
      );

      final first = await populator.populateAll('user-1');
      expect(first, 1);

      final second = await populator.populateAll('user-1');
      expect(second, 0);
    });
  });
}
