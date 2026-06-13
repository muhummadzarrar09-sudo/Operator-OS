import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  StatsTable,
  QuestsTable,
  HabitsTable,
  JournalEntriesTable,
  RoadmapDaysTable,
  SleepLogsTable,
  BossDaysTable,
  EntriesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.custom(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'operator_os_db');
  }
}
