class SupabaseConstants {
  // TODO: Replace these with your real Supabase project values before running.
  static const String url = 'https://your-project.supabase.co';
  static const String publishableKey = 'your-publishable-or-anon-key';
}

class XpConfig {
  /// Cumulative XP to reach level N = 50 × N².
  static int xpForLevel(int level) => 50 * level * level;

  /// Derives level from cumulative XP using integer thresholds.
  static int levelForXp(int xp) {
    int level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// Tier thresholds (config constant, not hardcoded inline).
  static const List<int> tierThresholds = [1, 3, 6, 10];

  /// Tier from level: 1 = hut (1-2), 2 = cottage (3-5), 3 = tower (6-9), 4 = castle (10+).
  static int tierForLevel(int level) {
    if (level < tierThresholds[1]) return 1;
    if (level < tierThresholds[2]) return 2;
    if (level < tierThresholds[3]) return 3;
    return 4;
  }

  static const int xpTrivial = 10;
  static const int xpStandard = 25;
  static const int xpHard = 75;
  static const int xpBossDefault = 300;
  static const int xpRecovery = 25;
}

enum StatKey {
  forge,
  academy,
  leverage,
  presence,
  craft,
  vitality,
  capital,
  clarity;

  String get label {
    return switch (this) {
      StatKey.forge => 'Forge',
      StatKey.academy => 'Academy',
      StatKey.leverage => 'Leverage',
      StatKey.presence => 'Presence',
      StatKey.craft => 'Craft',
      StatKey.vitality => 'Vitality',
      StatKey.capital => 'Capital',
      StatKey.clarity => 'Clarity',
    };
  }
}

enum QuestTier {
  trivial(XpConfig.xpTrivial),
  standard(XpConfig.xpStandard),
  hard(XpConfig.xpHard),
  boss(XpConfig.xpBossDefault),
  recovery(XpConfig.xpRecovery);

  final int xp;
  const QuestTier(this.xp);
}

enum Mood { drained, okay, good, great }

enum SleepQuality { poor, okay, good }

enum DayType { weekday, sundayBoss }

enum QuestStatus { pending, done }
