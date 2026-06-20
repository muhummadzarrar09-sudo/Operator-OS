import 'package:flutter/material.dart';
import 'constants.dart';

class BuildingConfig {
  static const Map<String, Color> statColors = {
    'forge': Color(0xFFE65100), // deep orange
    'academy': Color(0xFF1565C0), // blue
    'leverage': Color(0xFF2E7D32), // green
    'presence': Color(0xFF6A1B9A), // purple
    'craft': Color(0xFFAD1457), // pink
    'vitality': Color(0xFFC62828), // red
    'capital': Color(0xFFF9A825), // gold
    'clarity': Color(0xFF00838F), // cyan
  };

  static Color colorForStat(String statKey) {
    return statColors[statKey] ?? Colors.grey;
  }

  /// Stable CoC-style 2.5D world canvas. Kept intentionally modest so it
  /// renders reliably on phones and does not feel like a broken giant board.
  static const double worldWidth = 1800;
  static const double worldHeight = 1300;

  /// Tall isometric sprite box. Positions below are base anchors, not top-lefts.
  static const double buildingSpriteWidth = 220;
  static const double buildingSpriteHeight = 254;
  static const double buildingAnchorYOffset = 196;

  /// Fixed village layout for the 8 stat buildings.
  ///
  /// Each offset is the visual base/feet of the building. The renderer subtracts
  /// half sprite width and [buildingAnchorYOffset] so sprites rise upward like a
  /// real isometric game object instead of being cropped cards.
  static const Map<String, Offset> buildingPositions = {
    'forge': Offset(650, 390),
    'academy': Offset(900, 500),
    'leverage': Offset(1160, 500),
    'presence': Offset(560, 700),
    'craft': Offset(900, 650),
    'vitality': Offset(1240, 710),
    'capital': Offset(760, 910),
    'clarity': Offset(1040, 930),
  };

  /// Pace ghosts sit north-east on the isometric grid.
  static const double ghostOffsetX = 72;
  static const double ghostOffsetY = -34;

  static Offset ghostAnchorFor(Offset anchor) {
    return Offset(anchor.dx + ghostOffsetX, anchor.dy + ghostOffsetY);
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
