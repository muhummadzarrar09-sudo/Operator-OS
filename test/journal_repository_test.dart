import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';

void main() {
  group('JournalRepository', () {
    test('creates and retrieves entry for a date', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = JournalRepository(db);

      final date = DateTime(2024, 6, 14);
      await repo.saveEntry(
        userId: 'user-1',
        date: date,
        mood: Mood.great,
        sleepHours: 7.5,
        sleepQuality: SleepQuality.good,
        wins: 'Shipped feature',
        lessonLearned: 'Test early',
        tomorrowPlan: 'Rest',
        bigPictureNote: 'Stay consistent',
      );

      final entry = await repo.getEntryForDate('user-1', date);
      expect(entry, isNotNull);
      expect(entry!.mood, 'great');
      expect(entry.sleepHours, 7.5);
      expect(entry.sleepQuality, 'good');
      expect(entry.wins, 'Shipped feature');
    });

    test('updates existing entry', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = JournalRepository(db);

      final date = DateTime(2024, 6, 14);
      await repo.saveEntry(userId: 'user-1', date: date, mood: Mood.okay);
      await repo.saveEntry(userId: 'user-1', date: date, mood: Mood.great);

      final entries = await repo.watchEntries('user-1').first;
      expect(entries.length, 1);
      expect(entries.first.mood, 'great');
    });

    test('stream returns entries ordered by date desc', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = JournalRepository(db);

      await repo.saveEntry(userId: 'user-1', date: DateTime(2024, 6, 10), mood: Mood.okay);
      await repo.saveEntry(userId: 'user-1', date: DateTime(2024, 6, 12), mood: Mood.good);
      await repo.saveEntry(userId: 'user-1', date: DateTime(2024, 6, 14), mood: Mood.great);

      final entries = await repo.watchEntries('user-1').first;
      expect(entries.length, 3);
      expect(entries[0].mood, 'great');
      expect(entries[1].mood, 'good');
      expect(entries[2].mood, 'okay');
    });
  });
}
