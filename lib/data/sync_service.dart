import 'dart:typed_data';

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
  final _supabase = Supabase.instance.client;

  SyncService(this._db);

  Future<void> performSync() async {
    if (SupabaseConstants.url.contains('your-project') ||
        SupabaseConstants.publishableKey.contains('your-')) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('last_synced_at') ?? 0;

    // Push local → remote
    await _push(_db.select(_db.statsTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'stat_key': r.statKey,
      'level': r.level, 'current_xp': r.currentXp, 'sub_stats_json': r.subStatsJson,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'stats', lastSync);
    await _push(_db.select(_db.questsTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'domain': r.domain, 'title': r.title,
      'tier': r.tier, 'xp_value': r.xpValue, 'status': r.status,
      'due_date': r.dueDate, 'completed_at': r.completedAt, 'roadmap_day_id': r.roadmapDayId,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'quests', lastSync);
    await _push(_db.select(_db.habitsTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'domain': r.domain, 'name': r.name,
      'cadence': r.cadence, 'skip_tokens_remaining': r.skipTokensRemaining,
      'current_streak': r.currentStreak,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'habits', lastSync);
    await _push(_db.select(_db.journalEntriesTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'date': r.date, 'mood': r.mood,
      'sleep_hours': r.sleepHours, 'sleep_quality': r.sleepQuality,
      'wins': r.wins, 'lesson_learned': r.lessonLearned,
      'tomorrow_plan': r.tomorrowPlan, 'big_picture_note': r.bigPictureNote,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'journal_entries', lastSync);
    await _push(_db.select(_db.roadmapDaysTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'day_number': r.dayNumber, 'date': r.date,
      'day_type': r.dayType, 'slot_a': r.slotA, 'slot_b': r.slotB,
      'bedtime_target': r.bedtimeTarget, 'notes': r.notes, 'done': r.done,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'roadmap_days', lastSync);
    await _push(_db.select(_db.sleepLogsTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'date': r.date, 'bedtime': r.bedtime,
      'wake_time': r.wakeTime, 'duration_hours': r.durationHours, 'on_target': r.onTarget,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'sleep_logs', lastSync);
    await _push(_db.select(_db.bossDaysTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'date': r.date,
      'review_notes': r.reviewNotes, 'future_self_note': r.futureSelfNote,
      'perk_unlocked': r.perkUnlocked,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
    }, 'boss_days', lastSync);
    await _push(_db.select(_db.entriesTable).get, (r) => r.updatedAt, (r) => {
      'id': r.id, 'user_id': r.userId, 'domain': r.domain, 'entry_type': r.entryType,
      'title': r.title, 'body': r.body, 'content_hash': r.contentHash,
      'created_at': r.createdAt, 'updated_at': r.updatedAt,
      'embedding': r.embedding, 'embedding_model': r.embeddingModel,
      'embedding_dim': r.embeddingDim, 'embedded_at': r.embeddedAt,
    }, 'entries', lastSync);

    // Pull remote → local
    await _pull('stats', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.statsTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.statsTable).insertOnConflictUpdate(StatsTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        statKey: Value(json['stat_key'] as String), level: Value(json['level'] as int),
        currentXp: Value(json['current_xp'] as int), subStatsJson: Value(json['sub_stats_json'] as String),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('quests', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.questsTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.questsTable).insertOnConflictUpdate(QuestsTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        domain: Value(json['domain'] as String), title: Value(json['title'] as String),
        tier: Value(json['tier'] as String), xpValue: Value(json['xp_value'] as int),
        status: Value(json['status'] as String), dueDate: Value(json['due_date'] as int?),
        completedAt: Value(json['completed_at'] as int?), roadmapDayId: Value(json['roadmap_day_id'] as String?),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('habits', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.habitsTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.habitsTable).insertOnConflictUpdate(HabitsTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        domain: Value(json['domain'] as String), name: Value(json['name'] as String),
        cadence: Value(json['cadence'] as String), skipTokensRemaining: Value(json['skip_tokens_remaining'] as int),
        currentStreak: Value(json['current_streak'] as int),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('journal_entries', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.journalEntriesTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.journalEntriesTable).insertOnConflictUpdate(JournalEntriesTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        date: Value(json['date'] as int), mood: Value(json['mood'] as String),
        sleepHours: Value((json['sleep_hours'] as num?)?.toDouble()),
        sleepQuality: Value(json['sleep_quality'] as String?),
        wins: Value(json['wins'] as String), lessonLearned: Value(json['lesson_learned'] as String),
        tomorrowPlan: Value(json['tomorrow_plan'] as String), bigPictureNote: Value(json['big_picture_note'] as String),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('roadmap_days', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.roadmapDaysTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.roadmapDaysTable).insertOnConflictUpdate(RoadmapDaysTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        dayNumber: Value(json['day_number'] as int), date: Value(json['date'] as int),
        dayType: Value(json['day_type'] as String), slotA: Value(json['slot_a'] as String),
        slotB: Value(json['slot_b'] as String), bedtimeTarget: Value(json['bedtime_target'] as String),
        notes: Value(json['notes'] as String), done: Value(json['done'] as bool),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('sleep_logs', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.sleepLogsTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.sleepLogsTable).insertOnConflictUpdate(SleepLogsTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        date: Value(json['date'] as int), bedtime: Value(json['bedtime'] as int),
        wakeTime: Value(json['wake_time'] as int), durationHours: Value((json['duration_hours'] as num).toDouble()),
        onTarget: Value(json['on_target'] as bool),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('boss_days', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.bossDaysTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.bossDaysTable).insertOnConflictUpdate(BossDaysTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        date: Value(json['date'] as int), reviewNotes: Value(json['review_notes'] as String),
        futureSelfNote: Value(json['future_self_note'] as String), perkUnlocked: Value(json['perk_unlocked'] as String?),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
      ));
    });
    await _pull('entries', user.id, lastSync, (json) async {
      final ru = (json['updated_at'] as num).toInt();
      final ex = await (_db.select(_db.entriesTable)..where((t) => t.id.equals(json['id'] as String))).getSingleOrNull();
      if (ex != null && ru <= ex.updatedAt) return;
      await _db.into(_db.entriesTable).insertOnConflictUpdate(EntriesTableCompanion(
        id: Value(json['id'] as String), userId: Value(json['user_id'] as String),
        domain: Value(json['domain'] as String), entryType: Value(json['entry_type'] as String),
        title: Value(json['title'] as String), body: Value(json['body'] as String),
        contentHash: Value(json['content_hash'] as String),
        createdAt: Value(json['created_at'] as int), updatedAt: Value(ru),
        embedding: Value(json['embedding'] as Uint8List?), embeddingModel: Value(json['embedding_model'] as String?),
        embeddingDim: Value(json['embedding_dim'] as int?), embeddedAt: Value(json['embedded_at'] as int?),
      ));
    });

    await prefs.setInt('last_synced_at', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _push<T>(
    Future<List<T>> Function() query,
    int Function(T) updatedAt,
    Map<String, dynamic> Function(T) toPayload,
    String tableName,
    int lastSync,
  ) async {
    final rows = await query();
    final toPush = rows.where((r) => updatedAt(r) > lastSync).toList();
    if (toPush.isEmpty) return;
    await _supabase.from(tableName).upsert(toPush.map(toPayload).toList());
  }

  Future<void> _pull(
    String tableName,
    String userId,
    int lastSync,
    Future<void> Function(Map<String, dynamic> json) upsert,
  ) async {
    final response = await _supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync);
    for (final json in (response as List<dynamic>? ?? [])) {
      await upsert(json);
    }
  }
}
