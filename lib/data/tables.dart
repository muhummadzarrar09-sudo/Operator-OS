import 'package:drift/drift.dart';

@DataClassName('Stat')
class StatsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get statKey => text().named('stat_key')();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get currentXp => integer().named('current_xp').withDefault(const Constant(0))();
  TextColumn get subStatsJson => text().named('sub_stats_json').withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Quest')
class QuestsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get domain => text()();
  TextColumn get title => text()();
  TextColumn get tier => text()();
  IntColumn get xpValue => integer().named('xp_value')();
  TextColumn get status => text()();
  IntColumn get dueDate => integer().named('due_date').nullable()();
  IntColumn get completedAt => integer().named('completed_at').nullable()();
  TextColumn get roadmapDayId => text().named('roadmap_day_id').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Habit')
class HabitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get domain => text()();
  TextColumn get name => text()();
  TextColumn get cadence => text()();
  IntColumn get skipTokensRemaining => integer().named('skip_tokens_remaining').withDefault(const Constant(1))();
  IntColumn get currentStreak => integer().named('current_streak').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('JournalEntry')
class JournalEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  IntColumn get date => integer()();
  TextColumn get mood => text()();
  RealColumn get sleepHours => real().named('sleep_hours').nullable()();
  TextColumn get sleepQuality => text().named('sleep_quality').nullable()();
  TextColumn get wins => text().withDefault(const Constant(''))();
  TextColumn get lessonLearned => text().named('lesson_learned').withDefault(const Constant(''))();
  TextColumn get tomorrowPlan => text().named('tomorrow_plan').withDefault(const Constant(''))();
  TextColumn get bigPictureNote => text().named('big_picture_note').withDefault(const Constant(''))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoadmapDay')
class RoadmapDaysTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  IntColumn get dayNumber => integer().named('day_number')();
  IntColumn get date => integer()();
  TextColumn get dayType => text().named('day_type')();
  TextColumn get slotA => text().named('slot_a')();
  TextColumn get slotB => text().named('slot_b')();
  TextColumn get bedtimeTarget => text().named('bedtime_target')();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SleepLog')
class SleepLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  IntColumn get date => integer()();
  IntColumn get bedtime => integer()();
  IntColumn get wakeTime => integer().named('wake_time')();
  RealColumn get durationHours => real().named('duration_hours')();
  BoolColumn get onTarget => boolean().named('on_target').withDefault(const Constant(false))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BossDay')
class BossDaysTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  IntColumn get date => integer()();
  TextColumn get reviewNotes => text().named('review_notes').withDefault(const Constant(''))();
  TextColumn get futureSelfNote => text().named('future_self_note').withDefault(const Constant(''))();
  TextColumn get perkUnlocked => text().named('perk_unlocked').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Entry')
class EntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get domain => text()();
  TextColumn get entryType => text().named('entry_type')();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get contentHash => text().named('content_hash')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BlobColumn get embedding => blob().nullable()();
  TextColumn get embeddingModel => text().named('embedding_model').nullable()();
  IntColumn get embeddingDim => integer().named('embedding_dim').nullable()();
  IntColumn get embeddedAt => integer().named('embedded_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
