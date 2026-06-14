import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/journal_repository.dart';
import 'package:operator_os/data/repositories/quests_repository.dart';
import 'package:uuid/uuid.dart';

/// Populates the generic `entries` table from domain-specific tables
/// (journal_entries, quests, boss_days) so the RAG pipeline can index them.
class EntryPopulationService {
  final AppDatabase _db;
  final JournalRepository _journalRepo;
  final QuestsRepository _questsRepo;

  EntryPopulationService(
    this._db,
    this._journalRepo,
    this._questsRepo,
  );

  /// Scans all source tables and upserts into `entries`.
  /// Returns the number of new rows inserted.
  Future<int> populateAll(String userId) async {
    int inserted = 0;
    inserted += await _populateJournal(userId);
    inserted += await _populateQuests(userId);
    inserted += await _populateBossDays(userId);
    return inserted;
  }

  Future<int> _populateJournal(String userId) async {
    final entries = await _journalRepo.watchEntries(userId).first;
    int count = 0;
    for (final j in entries) {
      final body = _journalBody(j);
      final hash = _hash(body);
      if (await _exists(userId, hash)) continue;

      await _db.into(_db.entriesTable).insert(
            EntriesTableCompanion(
              id: Value(const Uuid().v4()),
              userId: Value(userId),
              domain: const Value('clarity'), // journal is self-reflection
              entryType: const Value('journal'),
              title: Value('Journal ${_dateLabel(j.date)}'),
              body: Value(body),
              contentHash: Value(hash),
              createdAt: Value(j.createdAt),
              updatedAt: Value(j.updatedAt),
            ),
          );
      count++;
    }
    return count;
  }

  Future<int> _populateQuests(String userId) async {
    final stats = await _db.select(_db.statsTable).get();
    int count = 0;
    for (final stat in stats.where((s) => s.userId == userId)) {
      final quests = await _questsRepo.getAllQuestsByDomain(userId, stat.statKey);
      for (final q in quests) {
        final body = '${q.title}. Status: ${q.status}. Tier: ${q.tier}. ${q.xpValue} XP.';
        final hash = _hash(body);
        if (await _exists(userId, hash)) continue;

        await _db.into(_db.entriesTable).insert(
              EntriesTableCompanion(
                id: Value(const Uuid().v4()),
                userId: Value(userId),
                domain: Value(q.domain),
                entryType: const Value('quest'),
                title: Value(q.title),
                body: Value(body),
                contentHash: Value(hash),
                createdAt: Value(q.createdAt),
                updatedAt: Value(q.updatedAt),
              ),
            );
        count++;
      }
    }
    return count;
  }

  Future<int> _populateBossDays(String userId) async {
    // Boss days are not exposed via a stream in BossRepository, so we
    // read directly from the table. We only need the most recent ones for RAG.
    final bossDays = await (_db.select(_db.bossDaysTable)
          ..where((b) => b.userId.equals(userId))
          ..orderBy([(b) => OrderingTerm.desc(b.date)])
          ..limit(100))
        .get();
    int count = 0;
    for (final b in bossDays) {
      final body = 'Weekly review: ${b.reviewNotes}. Future self note: ${b.futureSelfNote}.'
          '${b.perkUnlocked != null ? ' Perk unlocked: ${b.perkUnlocked}.' : ''}';
      final hash = _hash(body);
      if (await _exists(userId, hash)) continue;

      await _db.into(_db.entriesTable).insert(
            EntriesTableCompanion(
              id: Value(const Uuid().v4()),
              userId: Value(userId),
              domain: const Value('clarity'),
              entryType: const Value('boss_review'),
              title: Value('Boss Day ${_dateLabel(b.date)}'),
              body: Value(body),
              contentHash: Value(hash),
              createdAt: Value(b.createdAt),
              updatedAt: Value(b.updatedAt),
            ),
          );
      count++;
    }
    return count;
  }

  Future<bool> _exists(String userId, String hash) async {
    final existing = await (_db.select(_db.entriesTable)
          ..where(
            (e) => e.userId.equals(userId) & e.contentHash.equals(hash),
          )
          ..limit(1))
        .getSingleOrNull();
    return existing != null;
  }

  String _hash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  String _journalBody(JournalEntry j) {
    final parts = <String>[
      'Mood: ${j.mood}',
      if (j.sleepHours != null) 'Sleep: ${j.sleepHours}h (${j.sleepQuality ?? "unknown"})',
      if (j.wins.isNotEmpty) 'Wins: ${j.wins}',
      if (j.lessonLearned.isNotEmpty) 'Lesson: ${j.lessonLearned}',
      if (j.tomorrowPlan.isNotEmpty) 'Plan: ${j.tomorrowPlan}',
      if (j.bigPictureNote.isNotEmpty) 'Big picture: ${j.bigPictureNote}',
    ];
    return parts.join('. ');
  }

  String _dateLabel(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
