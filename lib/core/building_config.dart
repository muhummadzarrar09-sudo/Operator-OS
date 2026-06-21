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

  /// Matches assets/compound/compound_base.png exactly.
  ///
  /// The map is now a proper pre-rendered isometric base image, so the building
  /// anchors below are authored in the same raster map coordinate space. This
  /// avoids mixing an isometric diamond painter with arbitrary Cartesian points.
  static const double worldWidth = 1408;
  static const double worldHeight = 1408;

  /// Tall isometric sprite box. [buildingPositions] are base/feet anchors, not
  /// top-lefts. The rendered building image bottom aligns with the anchor and
  /// the label plate sits below it.
  static const double buildingSpriteWidth = 248;
  static const double buildingSpriteHeight = 292;
  static const double buildingAnchorYOffset = 254;

  /// Building base anchors matched to the visible pads on compound_base.png.
  static const Map<String, Offset> buildingPositions = {
    'forge': Offset(704, 314),
    'academy': Offset(535, 462),
    'leverage': Offset(878, 462),
    'presence': Offset(232, 704),
    'vitality': Offset(1176, 704),
    'craft': Offset(530, 970),
    'clarity': Offset(882, 970),
    'capital': Offset(704, 1164),
  };

  /// Pace ghosts sit slightly north-east on the visible map grid.
  static const double ghostOffsetX = 56;
  static const double ghostOffsetY = -36;

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
