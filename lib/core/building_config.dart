import 'package:flutter/material.dart';
import 'constants.dart';

class BuildingConfig {
  static const Map<String, Color> statColors = {
    'forge': Color(0xFFE65100),      // deep orange
    'academy': Color(0xFF1565C0),    // blue
    'leverage': Color(0xFF2E7D32),    // green
    'presence': Color(0xFF6A1B9A),   // purple
    'craft': Color(0xFFAD1457),      // pink
    'vitality': Color(0xFFC62828),    // red
    'capital': Color(0xFFF9A825),    // gold
    'clarity': Color(0xFF00838F),    // cyan
  };

  static Color colorForStat(String statKey) {
    return statColors[statKey] ?? Colors.grey;
  }

  /// Fixed village layout for the 8 buildings inside the 1500×1500 compound world.
  static const Map<String, Offset> buildingPositions = {
    'forge': Offset(300, 300),
    'academy': Offset(700, 250),
    'leverage': Offset(1100, 300),
    'presence': Offset(200, 700),
    'craft': Offset(650, 650),
    'vitality': Offset(1150, 700),
    'capital': Offset(450, 1100),
    'clarity': Offset(950, 1050),
  };

  static const double ghostOffsetX = 40;
  static const double ghostOffsetY = 40;
}

  static String tierName(int tier) {
    return switch (tier) {
      1 => 'Hut',
      2 => 'Cottage',
      3 => 'Tower',
      4 => 'Castle',
      _ => 'Unknown',
    };
  }
}

class PaceConfig {
  static const int defaultXpPerDay = 50;

  static int paceLevelForStat(String statKey, int daysSinceInstall) {
    final targetXp = daysSinceInstall * defaultXpPerDay;
    return XpConfig.levelForXp(targetXp);
  }

  static int paceTierForStat(String statKey, int daysSinceInstall) {
    return XpConfig.tierForLevel(paceLevelForStat(statKey, daysSinceInstall));
  }
}
