import 'package:flutter/material.dart';
import 'package:operator_os/core/operator_style.dart';

class OperatorWorldHud extends StatelessWidget {
  final int compoundLevel;
  final int totalXp;
  final int activeMissions;
  final String campaignLabel;
  final String councilLabel;
  final bool compact;

  const OperatorWorldHud({
    required this.compoundLevel,
    required this.totalXp,
    required this.activeMissions,
    required this.campaignLabel,
    this.councilLabel = 'Council Ready',
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HudTile(
        icon: Icons.home_work_outlined,
        label: 'Compound',
        value: 'Lv $compoundLevel',
        color: OperatorPalette.parchmentGold,
      ),
      _HudTile(
        icon: Icons.bolt_outlined,
        label: 'Total XP',
        value: _formatNumber(totalXp),
        color: OperatorPalette.torchOrange,
      ),
      _HudTile(
        icon: Icons.assignment_outlined,
        label: 'Missions',
        value: '$activeMissions',
        color: OperatorPalette.successGreen,
      ),
      _HudTile(
        icon: Icons.flag_outlined,
        label: 'Campaign',
        value: campaignLabel,
        color: OperatorPalette.hologramBlue,
      ),
      if (!compact)
        _HudTile(
          icon: Icons.psychology_alt_outlined,
          label: 'Council',
          value: councilLabel,
          color: OperatorPalette.parchmentGold,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OperatorPalette.panelDark.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OperatorPalette.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _withSpacing(tiles)),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tiles,
            ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 8));
      spaced.add(children[i]);
    }
    return spaced;
  }

  String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class _HudTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: OperatorPalette.voidBlack.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OperatorPalette.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
