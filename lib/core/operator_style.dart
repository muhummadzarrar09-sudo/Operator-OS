import 'package:flutter/material.dart';

/// Phase 1 visual/copy layer for the Operator OS world.
///
/// UI-only. No data, XP, auth, sync, schema, dependency, or repository logic.
class OperatorPalette {
  static const Color voidBlack = Color(0xFF090D16);
  static const Color nightNavy = Color(0xFF0F172A);
  static const Color panelDark = Color(0xFF151A2E);
  static const Color panelRaised = Color(0xFF1C2340);
  static const Color borderDim = Color(0xFF2A3354);
  static const Color parchmentGold = Color(0xFFD6B86A);
  static const Color torchOrange = Color(0xFFFF8A2A);
  static const Color emberRed = Color(0xFFE65100);
  static const Color hologramBlue = Color(0xFF58D7FF);
  static const Color successGreen = Color(0xFF4ADE80);
  static const Color warningAmber = Color(0xFFF2B84B);
  static const Color dangerRed = Color(0xFFE84855);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFAAB2C8);
  static const Color textMuted = Color(0xFF6F7894);
}

class OperatorCopy {
  static const List<String> loadingLines = [
    'Restoring Compound state...',
    'Reading the quest board...',
    'Lighting the Forge...',
    'Summoning the War Council...',
    'Opening the gates...',
  ];

  static String statLabel(String statKey) {
    return switch (statKey) {
      'forge' => 'Forge',
      'academy' => 'Academy',
      'leverage' => 'Leverage Hall',
      'presence' => 'Presence Hall',
      'craft' => 'Craft Studio',
      'vitality' => 'Vitality Grounds',
      'capital' => 'Treasury',
      'clarity' => 'Observatory',
      _ => statKey.toUpperCase(),
    };
  }

  static String shortStatLabel(String statKey) {
    return switch (statKey) {
      'forge' => 'Forge',
      'academy' => 'Academy',
      'leverage' => 'Leverage',
      'presence' => 'Presence',
      'craft' => 'Craft',
      'vitality' => 'Vitality',
      'capital' => 'Capital',
      'clarity' => 'Clarity',
      _ => statKey.toUpperCase(),
    };
  }

  static String buildingLine(String statKey) {
    return switch (statKey) {
      'forge' => 'The Forge burns brighter.',
      'academy' => 'The Academy shelves grow heavier.',
      'leverage' => 'The Market gains another contract.',
      'presence' => 'The Command Hall stands taller.',
      'craft' => 'The Studio grows stronger.',
      'vitality' => 'The Vitality Grounds recover power.',
      'capital' => 'The Treasury locks in value.',
      'clarity' => 'The Observatory clears more fog.',
      _ => 'The Compound grows stronger.',
    };
  }

  static String missionTier(String tier) {
    return switch (tier) {
      'trivial' => 'QUICK TASK',
      'standard' => 'MISSION',
      'hard' => 'HARD MISSION',
      'boss' => 'BOSS MISSION',
      'recovery' => 'RECOVERY',
      _ => tier.toUpperCase(),
    };
  }

  static String tierName(int tier) {
    return switch (tier) {
      1 => 'Outpost',
      2 => 'Built Structure',
      3 => 'Specialized Tower',
      4 => 'Legendary Hall',
      _ => 'Unknown Tier',
    };
  }
}

class OperatorTextStyles {
  static const TextStyle overline = TextStyle(
    color: OperatorPalette.parchmentGold,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );

  static const TextStyle title = TextStyle(
    color: OperatorPalette.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );

  static const TextStyle body = TextStyle(
    color: OperatorPalette.textSecondary,
    fontSize: 14,
    height: 1.35,
  );

  static const TextStyle muted = TextStyle(
    color: OperatorPalette.textMuted,
    fontSize: 12,
    height: 1.3,
  );
}

class OperatorGradients {
  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      OperatorPalette.panelRaised,
      OperatorPalette.panelDark,
    ],
  );

  static const RadialGradient ember = RadialGradient(
    center: Alignment.topRight,
    radius: 1.4,
    colors: [
      Color(0x33FF8A2A),
      Color(0x00151A2E),
    ],
  );
}
