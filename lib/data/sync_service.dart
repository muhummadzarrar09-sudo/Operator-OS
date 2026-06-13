import 'package:drift/drift.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sync_service.g.dart';

@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncService(db);
}

class SyncService {
  final AppDatabase _db;

  SyncService(this._db);
  final _supabase = Supabase.instance.client;

  Future<void> performSync() async {
    // Skip if Supabase is not configured yet.
    if (SupabaseConstants.url.contains('your-project') ||
        SupabaseConstants.publishableKey.contains('your-')) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('last_synced_at') ?? 0;

    // Push local changes newer than last sync.
    await _pushStats(lastSync);
    await _pushQuests(lastSync);
    await _pushHabits(lastSync);
    await _pushJournalEntries(lastSync);
    await _pushRoadmapDays(lastSync);
    await _pushSleepLogs(lastSync);
    await _pushBossDays(lastSync);
    await _pushEntries(lastSync);

    // Pull remote changes newer than last sync.
    await _pullStats(lastSync, user.id);
    await _pullQuests(lastSync, user.id);
    await _pullHabits(lastSync, user.id);
    await _pullJournalEntries(lastSync, user.id);
    await _pullRoadmapDays(lastSync, user.id);
    await _pullSleepLogs(lastSync, user.id);
    await _pullBossDays(lastSync, user.id);
    await _pullEntries(lastSync, user.id);

    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('last_synced_at', now);
  }

  // =========================================================
  // PUSH
  // =========================================================

  Future<void> _pushStats(int lastSync) async {
    final rows = await _db.select(_db.statsTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'stat_key': r.statKey,
      'level': r.level,
      'current_xp': r.currentXp,
      'sub_stats_json': r.subStatsJson,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('stats').upsert(payload);
  }

  Future<void> _pushQuests(int lastSync) async {
    final rows = await _db.select(_db.questsTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'domain': r.domain,
      'title': r.title,
      'tier': r.tier,
      'xp_value': r.xpValue,
      'status': r.status,
      'due_date': r.dueDate,
      'completed_at': r.completedAt,
      'roadmap_day_id': r.roadmapDayId,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('quests').upsert(payload);
  }

  Future<void> _pushHabits(int lastSync) async {
    final rows = await _db.select(_db.habitsTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'domain': r.domain,
      'name': r.name,
      'cadence': r.cadence,
      'skip_tokens_remaining': r.skipTokensRemaining,
      'current_streak': r.currentStreak,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('habits').upsert(payload);
  }

  Future<void> _pushJournalEntries(int lastSync) async {
    final rows = await _db.select(_db.journalEntriesTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'date': r.date,
      'mood': r.mood,
      'sleep_hours': r.sleepHours,
      'sleep_quality': r.sleepQuality,
      'wins': r.wins,
      'lesson_learned': r.lessonLearned,
      'tomorrow_plan': r.tomorrowPlan,
      'big_picture_note': r.bigPictureNote,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('journal_entries').upsert(payload);
  }

  Future<void> _pushRoadmapDays(int lastSync) async {
    final rows = await _db.select(_db.roadmapDaysTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'day_number': r.dayNumber,
      'date': r.date,
      'day_type': r.dayType,
      'slot_a': r.slotA,
      'slot_b': r.slotB,
      'bedtime_target': r.bedtimeTarget,
      'notes': r.notes,
      'done': r.done,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('roadmap_days').upsert(payload);
  }

  Future<void> _pushSleepLogs(int lastSync) async {
    final rows = await _db.select(_db.sleepLogsTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'date': r.date,
      'bedtime': r.bedtime,
      'wake_time': r.wakeTime,
      'duration_hours': r.durationHours,
      'on_target': r.onTarget,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('sleep_logs').upsert(payload);
  }

  Future<void> _pushBossDays(int lastSync) async {
    final rows = await _db.select(_db.bossDaysTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'date': r.date,
      'review_notes': r.reviewNotes,
      'future_self_note': r.futureSelfNote,
      'perk_unlocked': r.perkUnlocked,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
    }).toList();
    await _supabase.from('boss_days').upsert(payload);
  }

  Future<void> _pushEntries(int lastSync) async {
    final rows = await _db.select(_db.entriesTable).get();
    final toPush = rows.where((r) => r.updatedAt > lastSync).toList();
    if (toPush.isEmpty) return;
    final payload = toPush.map((r) => {
      'id': r.id,
      'user_id': r.userId,
      'domain': r.domain,
      'entry_type': r.entryType,
      'title': r.title,
      'body': r.body,
      'content_hash': r.contentHash,
      'created_at': r.createdAt,
      'updated_at': r.updatedAt,
      'embedding': r.embedding,
      'embedding_model': r.embeddingModel,
      'embedding_dim': r.embeddingDim,
      'embedded_at': r.embeddedAt,
    }).toList();
    await _supabase.from('entries').upsert(payload);
  }

  // =========================================================
  // PULL
  // =========================================================

  Future<void> _pullStats(int lastSync, String userId) async {
    final response = await _supabase
        .from('stats')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.statsTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.statsTable).insertOnConflictUpdate(
              StatsTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                statKey: Value(json['stat_key'] as String),
                level: Value(json['level'] as int),
                currentXp: Value(json['current_xp'] as int),
                subStatsJson: Value(json['sub_stats_json'] as String),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullQuests(int lastSync, String userId) async {
    final response = await _supabase
        .from('quests')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.questsTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.questsTable).insertOnConflictUpdate(
              QuestsTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                domain: Value(json['domain'] as String),
                title: Value(json['title'] as String),
                tier: Value(json['tier'] as String),
                xpValue: Value(json['xp_value'] as int),
                status: Value(json['status'] as String),
                dueDate: Value(json['due_date'] as int?),
                completedAt: Value(json['completed_at'] as int?),
                roadmapDayId: Value(json['roadmap_day_id'] as String?),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullHabits(int lastSync, String userId) async {
    final response = await _supabase
        .from('habits')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.habitsTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.habitsTable).insertOnConflictUpdate(
              HabitsTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                domain: Value(json['domain'] as String),
                name: Value(json['name'] as String),
                cadence: Value(json['cadence'] as String),
                skipTokensRemaining: Value(json['skip_tokens_remaining'] as int),
                currentStreak: Value(json['current_streak'] as int),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullJournalEntries(int lastSync, String userId) async {
    final response = await _supabase
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.journalEntriesTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.journalEntriesTable).insertOnConflictUpdate(
              JournalEntriesTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                date: Value(json['date'] as int),
                mood: Value(json['mood'] as String),
                sleepHours: Value((json['sleep_hours'] as num?)?.toDouble()),
                sleepQuality: Value(json['sleep_quality'] as String?),
                wins: Value(json['wins'] as String),
                lessonLearned: Value(json['lesson_learned'] as String),
                tomorrowPlan: Value(json['tomorrow_plan'] as String),
                bigPictureNote: Value(json['big_picture_note'] as String),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullRoadmapDays(int lastSync, String userId) async {
    final response = await _supabase
        .from('roadmap_days')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.roadmapDaysTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.roadmapDaysTable).insertOnConflictUpdate(
              RoadmapDaysTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                dayNumber: Value(json['day_number'] as int),
                date: Value(json['date'] as int),
                dayType: Value(json['day_type'] as String),
                slotA: Value(json['slot_a'] as String),
                slotB: Value(json['slot_b'] as String),
                bedtimeTarget: Value(json['bedtime_target'] as String),
                notes: Value(json['notes'] as String),
                done: Value(json['done'] as bool),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullSleepLogs(int lastSync, String userId) async {
    final response = await _supabase
        .from('sleep_logs')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.sleepLogsTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.sleepLogsTable).insertOnConflictUpdate(
              SleepLogsTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                date: Value(json['date'] as int),
                bedtime: Value(json['bedtime'] as int),
                wakeTime: Value(json['wake_time'] as int),
                durationHours: Value((json['duration_hours'] as num).toDouble()),
                onTarget: Value(json['on_target'] as bool),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullBossDays(int lastSync, String userId) async {
    final response = await _supabase
        .from('boss_days')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.bossDaysTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.bossDaysTable).insertOnConflictUpdate(
              BossDaysTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                date: Value(json['date'] as int),
                reviewNotes: Value(json['review_notes'] as String),
                futureSelfNote: Value(json['future_self_note'] as String),
                perkUnlocked: Value(json['perk_unlocked'] as String?),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
              ),
            );
      }
    }
  }

  Future<void> _pullEntries(int lastSync, String userId) async {
    final response = await _supabase
        .from('entries')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    final rows = (response as List<dynamic>?) ?? [];
    for (final json in rows) {
      final remoteUpdated = (json['updated_at'] as num).toInt();
      final existing = await (_db.select(_db.entriesTable)
            ..where((t) => t.id.equals(json['id'] as String)))
          .getSingleOrNull();
      if (existing == null || remoteUpdated > existing.updatedAt) {
        await _db.into(_db.entriesTable).insertOnConflictUpdate(
              EntriesTableCompanion(
                id: Value(json['id'] as String),
                userId: Value(json['user_id'] as String),
                domain: Value(json['domain'] as String),
                entryType: Value(json['entry_type'] as String),
                title: Value(json['title'] as String),
                body: Value(json['body'] as String),
                contentHash: Value(json['content_hash'] as String),
                createdAt: Value(json['created_at'] as int),
                updatedAt: Value(remoteUpdated),
                embedding: Value(json['embedding'] as Uint8List?),
                embeddingModel: Value(json['embedding_model'] as String?),
                embeddingDim: Value(json['embedding_dim'] as int?),
                embeddedAt: Value(json['embedded_at'] as int?),
              ),
            );
      }
    }
  }
}
