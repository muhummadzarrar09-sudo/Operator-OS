import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/habits_repository.dart';

void main() {
  late AppDatabase db;
  late HabitsRepository repo;

  setUp(() {
    db = AppDatabase.custom(NativeDatabase.memory());
    repo = HabitsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('HabitsRepository', () {
    test('missing a habit decrements skip tokens without resetting streak', () async {
      await repo.createHabit(
        userId: 'user-1',
        domain: 'forge',
        name: 'Code daily',
        cadence: 'daily',
      );
      final habits = await repo.getHabitsByDomain('user-1', 'forge');
      final habit = habits.first;
      expect(habit.skipTokensRemaining, 1);
      expect(habit.currentStreak, 0);

      await repo.recordHabitCompletion(habit.id);
      final afterComplete = await repo.getHabit(habit.id);
      expect(afterComplete!.currentStreak, 1);
      expect(afterComplete.skipTokensRemaining, 1);

      await repo.recordHabitMiss(habit.id);
      final afterMiss = await repo.getHabit(habit.id);
      expect(afterMiss!.currentStreak, 1); // streak NOT reset
      expect(afterMiss.skipTokensRemaining, 0); // decremented by 1
    });

    test('miss with zero tokens does not go negative', () async {
      await repo.createHabit(
        userId: 'user-1',
        domain: 'forge',
        name: 'Read docs',
        cadence: 'daily',
      );
      final habits = await repo.getHabitsByDomain('user-1', 'forge');
      final habit = habits.first;

      // First miss: 1 -> 0
      await repo.recordHabitMiss(habit.id);
      final afterFirst = await repo.getHabit(habit.id);
      expect(afterFirst!.skipTokensRemaining, 0);
      expect(afterFirst.currentStreak, 0);

      // Second miss: 0 -> 0 (min clamped)
      await repo.recordHabitMiss(habit.id);
      final afterSecond = await repo.getHabit(habit.id);
      expect(afterSecond!.skipTokensRemaining, 0);
      expect(afterSecond.currentStreak, 0); // still not reset
    });

    test('completion increments streak repeatedly', () async {
      await repo.createHabit(
        userId: 'user-1',
        domain: 'academy',
        name: 'Study',
        cadence: 'daily',
      );
      final habits = await repo.getHabitsByDomain('user-1', 'academy');
      final habit = habits.first;

      await repo.recordHabitCompletion(habit.id);
      await repo.recordHabitCompletion(habit.id);
      await repo.recordHabitCompletion(habit.id);

      final after = await repo.getHabit(habit.id);
      expect(after!.currentStreak, 3);
    });

    test('stream emits habits by domain', () async {
      await repo.createHabit(
        userId: 'user-1',
        domain: 'vitality',
        name: 'Workout',
        cadence: 'daily',
      );

      final stream = repo.watchHabitsByDomain('user-1', 'vitality');
      await expectLater(
        stream,
        emits(
          predicate<List<Habit>>(
            (habits) => habits.length == 1 && habits.first.name == 'Workout',
          ),
        ),
      );
    });
  });
}
