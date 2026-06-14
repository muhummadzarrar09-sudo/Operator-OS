import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/roadmap_repository.dart';

void main() {
  group('RoadmapRepository generation', () {
    test('generates at least 60 days on first call', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = RoadmapRepository(db);

      final installDate = DateTime(2024, 1, 1); // Monday
      await repo.ensureDaysGenerated('user-1', installDate);

      final days = await repo.watchDays('user-1').first;
      expect(days.length, greaterThanOrEqualTo(60));
    });

    test('Day 1 equals install date', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = RoadmapRepository(db);

      final installDate = DateTime(2024, 1, 1); // Monday
      await repo.ensureDaysGenerated('user-1', installDate);

      final day1 = await repo.getDayByDate('user-1', installDate);
      expect(day1, isNotNull);
      expect(day1!.dayNumber, 1);
      expect(day1.dayType, 'weekday');
    });

    test('Sunday is sundayBoss with free roam slots and flex bedtime', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = RoadmapRepository(db);

      final installDate = DateTime(2024, 1, 1); // Monday
      await repo.ensureDaysGenerated('user-1', installDate);

      // Jan 1 2024 is Monday. Jan 7 is Sunday (day 7).
      final sunday = await repo.getDayByDate('user-1', DateTime(2024, 1, 7));
      expect(sunday, isNotNull);
      expect(sunday!.dayType, 'sundayBoss');
      expect(sunday.slotA, 'boss_day_free_roam');
      expect(sunday.slotB, 'boss_day_free_roam');
      expect(sunday.bedtimeTarget, 'Flex - short night');
    });

    test('weekday rotation matches spec (first 6 weekdays)', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = RoadmapRepository(db);

      final installDate = DateTime(2024, 1, 1); // Monday
      await repo.ensureDaysGenerated('user-1', installDate);

      // Day 1 (Mon): pos 1 -> (LEVERAGE, CRAFT)
      // Day 2 (Tue): pos 2 -> (CAPITAL, LEVERAGE)
      // Day 3 (Wed): pos 3 -> (CRAFT, CAPITAL)
      // Day 4 (Thu): pos 4 -> (LEVERAGE, CRAFT)
      // Day 5 (Fri): pos 5 -> (CAPITAL, LEVERAGE)
      // Day 6 (Sat): pos 6 -> (CRAFT, CAPITAL)
      // Day 7 (Sun): boss
      // Day 8 (Mon): pos 1 -> (LEVERAGE, CRAFT) again

      final d1 = await repo.getDayByDate('user-1', DateTime(2024, 1, 1));
      expect(d1!.slotA, 'leverage');
      expect(d1.slotB, 'craft');

      final d2 = await repo.getDayByDate('user-1', DateTime(2024, 1, 2));
      expect(d2!.slotA, 'capital');
      expect(d2.slotB, 'leverage');

      final d3 = await repo.getDayByDate('user-1', DateTime(2024, 1, 3));
      expect(d3!.slotA, 'craft');
      expect(d3.slotB, 'capital');

      final d8 = await repo.getDayByDate('user-1', DateTime(2024, 1, 8));
      expect(d8!.slotA, 'leverage');
      expect(d8.slotB, 'craft');
    });

    test('bedtime targets match spec', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = RoadmapRepository(db);

      final installDate = DateTime(2024, 1, 1); // Monday
      await repo.ensureDaysGenerated('user-1', installDate);

      // Day 13 (Sat Jan 13) -> 10:45 PM (Sundays get flex regardless)
      final d13 = await repo.getDayByDate('user-1', DateTime(2024, 1, 13));
      expect(d13!.bedtimeTarget, '10:45 PM');

      // Day 15 (Mon Jan 15) -> 10:30 PM
      final d15 = await repo.getDayByDate('user-1', DateTime(2024, 1, 15));
      expect(d15!.bedtimeTarget, '10:30 PM');

      // Day 20 (Sat Jan 20) -> 10:30 PM (Day 21 is Sunday)
      final d20 = await repo.getDayByDate('user-1', DateTime(2024, 1, 20));
      expect(d20!.bedtimeTarget, '10:30 PM');

      // Day 22 (Mon Jan 22) -> 10:15 PM
      final d22 = await repo.getDayByDate('user-1', DateTime(2024, 1, 22));
      expect(d22!.bedtimeTarget, '10:15 PM');

      // Day 27 (Sat Jan 27) -> 10:15 PM (Day 28 is Sunday)
      final d27 = await repo.getDayByDate('user-1', DateTime(2024, 1, 27));
      expect(d27!.bedtimeTarget, '10:15 PM');

      // Day 29 (Mon Jan 29) -> 10:00 PM
      final d29 = await repo.getDayByDate('user-1', DateTime(2024, 1, 29));
      expect(d29!.bedtimeTarget, '10:00 PM');

      // Day 43 (Mon Feb 12) -> 09:45 PM
      final d43 = await repo.getDayByDate('user-1', DateTime(2024, 2, 12));
      expect(d43!.bedtimeTarget, '09:45 PM');
    });

    test('markDayDone updates done flag', () async {
      final db = AppDatabase.custom(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = RoadmapRepository(db);

      final installDate = DateTime(2024, 1, 1);
      await repo.ensureDaysGenerated('user-1', installDate);

      final day = await repo.getDayByDate('user-1', installDate);
      expect(day!.done, false);

      await repo.markDayDone(day.id, true);
      final updated = await repo.getDayByDate('user-1', installDate);
      expect(updated!.done, true);
    });
  });
}
