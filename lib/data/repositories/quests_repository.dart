import 'package:drift/drift.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'quests_repository.g.dart';

@riverpod
QuestsRepository questsRepository(Ref ref) {
  return QuestsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(statsRepositoryProvider),
  );
}

class QuestsRepository {
  final AppDatabase _db;
  final StatsRepository _statsRepo;

  QuestsRepository(this._db, this._statsRepo);

  Future<void> createQuest({
    required String userId,
    required String domain,
    required String title,
    required QuestTier tier,
    DateTime? dueDate,
    String? roadmapDayId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.questsTable).insert(
          QuestsTableCompanion(
            id: Value(Uuid().v4()),
            userId: Value(userId),
            domain: Value(domain),
            title: Value(title),
            tier: Value(tier.name),
            xpValue: Value(tier.xp),
            status: Value(QuestStatus.pending.name),
            dueDate: Value(dueDate?.millisecondsSinceEpoch),
            roadmapDayId: Value(roadmapDayId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<List<Quest>> getPendingQuestsByDomain(String userId, String domain) async {
    return (_db.select(_db.questsTable)
          ..where(
            (q) =>
                q.userId.equals(userId) &
                q.domain.equals(domain) &
                q.status.equals(QuestStatus.pending.name),
          ))
        .get();
  }

  Future<List<Quest>> getDoneQuestsByDomain(String userId, String domain) async {
    return (_db.select(_db.questsTable)
          ..where(
            (q) =>
                q.userId.equals(userId) &
                q.domain.equals(domain) &
                q.status.equals(QuestStatus.done.name),
          ))
        .get();
  }

  Future<List<Quest>> getAllQuestsByDomain(String userId, String domain) async {
    return (_db.select(_db.questsTable)
          ..where(
            (q) => q.userId.equals(userId) & q.domain.equals(domain),
          ))
        .get();
  }

  Future<Quest?> getQuest(String userId, String questId) async {
    return (_db.select(_db.questsTable)
          ..where(
            (q) => q.userId.equals(userId) & q.id.equals(questId),
          ))
        .getSingleOrNull();
  }

  Stream<List<Quest>> watchPendingQuestsByDomain(String userId, String domain) {
    return (_db.select(_db.questsTable)
          ..where(
            (q) =>
                q.userId.equals(userId) &
                q.domain.equals(domain) &
                q.status.equals(QuestStatus.pending.name),
          ))
        .watch();
  }

  Stream<List<Quest>> watchAllPendingQuests(String userId) {
    return (_db.select(_db.questsTable)
          ..where(
            (q) =>
                q.userId.equals(userId) &
                q.status.equals(QuestStatus.pending.name),
          ))
        .watch();
  }

  /// Marks a quest as done and awards its XP to the linked stat.
  Future<void> completeQuest(String userId, String questId) async {
    final quest = await getQuest(userId, questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }
    if (quest.status == QuestStatus.done.name) {
      throw Exception('Quest already completed: $questId');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.update(_db.questsTable)..where((q) => q.id.equals(questId)))
          .write(
        QuestsTableCompanion(
          status: Value(QuestStatus.done.name),
          completedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _statsRepo.addXp(userId, quest.domain, quest.xpValue);
    });
  }
}
