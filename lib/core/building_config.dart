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

  /// Compound world dimensions. These are intentionally larger than the
  /// visible viewport so the InteractiveViewer can behave like a CoC-style
  /// camera over a real map rather than a flat fitted card.
  static const double worldWidth = 2200;
  static const double worldHeight = 1700;

  /// Building widgets are rendered as free-standing sprites, not clipped card
  /// thumbnails. The anchor point is the sprite's isometric base/feet.
  static const double buildingSpriteWidth = 240;
  static const double buildingSpriteHeight = 276;
  static const double buildingAnchorYOffset = 212;

  /// Fixed village layout for the 8 buildings inside the compound world.
  ///
  /// These offsets are isometric base anchors, not top-left corners. Rendering
  /// code subtracts [buildingSpriteWidth] / 2 and [buildingAnchorYOffset] so
  /// tall sprites can rise upward without being clipped.
  static const Map<String, Offset> buildingPositions = {
    'forge': Offset(760, 620),
    'academy': Offset(1100, 460),
    'leverage': Offset(1440, 650),
    'presence': Offset(600, 880),
    'craft': Offset(1070, 820),
    'vitality': Offset(1520, 920),
    'capital': Offset(860, 1160),
    'clarity': Offset(1260, 1180),
  };

  /// Pace ghosts sit slightly north-east of the real building, matching the
  /// screen-space direction of the isometric terrain grid.
  static const double ghostOffsetX = 86;
  static const double ghostOffsetY = -42;

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
