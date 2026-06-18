class CampaignSeason {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final int durationDays;
  final List<String> primaryStats;
  final List<String> secondaryStats;
  final List<String> maintenanceStats;
  final String directive;
  final String councilTone;

  const CampaignSeason({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.durationDays,
    required this.primaryStats,
    required this.secondaryStats,
    required this.maintenanceStats,
    required this.directive,
    required this.councilTone,
  });
}

class CampaignPresets {
  static const List<CampaignSeason> all = [
    CampaignSeason(
      id: 'ship_the_craft',
      name: 'Ship the Craft',
      tagline: 'Output over overthinking.',
      description: 'Create visible work, finish artifacts, and kill scope creep.',
      durationDays: 30,
      primaryStats: ['craft', 'forge'],
      secondaryStats: ['clarity', 'leverage'],
      maintenanceStats: ['academy', 'presence', 'vitality', 'capital'],
      directive: 'Produce one visible artifact before the day gets noisy.',
      councilTone: 'Direct, creative, anti-overthinking, shipping-focused.',
    ),
    CampaignSeason(
      id: 'build_the_machine',
      name: 'Build the Machine',
      tagline: 'Body first. Energy compounds.',
      description: 'Rebuild physical discipline, recovery, and baseline energy.',
      durationDays: 30,
      primaryStats: ['vitality', 'forge'],
      secondaryStats: ['clarity', 'presence'],
      maintenanceStats: ['academy', 'craft', 'capital', 'leverage'],
      directive: 'Protect recovery and complete one physical discipline rep.',
      councilTone: 'Grounded, physical, disciplined, recovery-aware.',
    ),
    CampaignSeason(
      id: 'lock_in_academically',
      name: 'Lock In Academically',
      tagline: 'Study like it counts.',
      description: 'Turn learning into tested understanding and measurable progress.',
      durationDays: 30,
      primaryStats: ['academy', 'clarity'],
      secondaryStats: ['forge', 'vitality'],
      maintenanceStats: ['capital', 'craft', 'leverage', 'presence'],
      directive: 'Solve, test, review mistakes. Avoid fake studying.',
      councilTone: 'Precise, exam-war focused, anti-fake-productivity.',
    ),
    CampaignSeason(
      id: 'build_the_empire',
      name: 'Build the Empire',
      tagline: 'Value, leverage, capital.',
      description: 'Focus on money, offers, outreach, negotiation, and financial reality.',
      durationDays: 30,
      primaryStats: ['capital', 'leverage'],
      secondaryStats: ['presence', 'craft'],
      maintenanceStats: ['forge', 'academy', 'vitality', 'clarity'],
      directive: 'Make contact with reality: build, sell, ask, track.',
      councilTone: 'Strategic, commercial, direct, value-focused.',
    ),
    CampaignSeason(
      id: 'become_dangerous',
      name: 'Become Dangerous',
      tagline: 'Capability over comfort.',
      description: 'Build physical, mental, and social edge without losing clarity.',
      durationDays: 30,
      primaryStats: ['presence', 'forge', 'vitality'],
      secondaryStats: ['clarity', 'leverage'],
      maintenanceStats: ['academy', 'craft', 'capital'],
      directive: 'Choose the action that increases capability today.',
      councilTone: 'Strong, challenging, but never reckless or cringe.',
    ),
    CampaignSeason(
      id: 'restore_the_signal',
      name: 'Restore the Signal',
      tagline: 'Clear the fog. Recover command.',
      description: 'Reduce noise, recover energy, and restore clarity during overloaded seasons.',
      durationDays: 30,
      primaryStats: ['clarity', 'vitality'],
      secondaryStats: ['academy', 'presence'],
      maintenanceStats: ['forge', 'craft', 'capital', 'leverage'],
      directive: 'Remove noise and choose one clean next action.',
      councilTone: 'Calm, honest, restorative, simple.',
    ),
  ];

  static CampaignSeason? byId(String? id) {
    if (id == null) return null;
    for (final season in all) {
      if (season.id == id) return season;
    }
    return null;
  }
}

class ActiveCampaign {
  final CampaignSeason? season;
  final DateTime? startedAt;

  const ActiveCampaign({this.season, this.startedAt});

  bool get hasCampaign => season != null && startedAt != null;

  int get dayNumber {
    if (!hasCampaign) return 0;
    final now = DateTime.now();
    final start = DateTime(startedAt!.year, startedAt!.month, startedAt!.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  int get daysRemaining {
    if (!hasCampaign) return 0;
    return (season!.durationDays - dayNumber).clamp(0, season!.durationDays).toInt();
  }

  double get progress {
    if (!hasCampaign) return 0;
    return (dayNumber / season!.durationDays).clamp(0.0, 1.0).toDouble();
  }
}
