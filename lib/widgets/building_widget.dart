import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';

class BuildingWidget extends StatefulWidget {
  final String statKey;
  final int level;
  final int currentXp;
  final int tier;
  final bool hasPendingQuests;
  final bool isGhost;
  final VoidCallback? onTap;

  const BuildingWidget({
    required this.statKey,
    required this.level,
    required this.currentXp,
    required this.tier,
    this.hasPendingQuests = false,
    this.isGhost = false,
    this.onTap,
    super.key,
  });

  @override
  State<BuildingWidget> createState() => _BuildingWidgetState();
}

class _BuildingWidgetState extends State<BuildingWidget> {
  bool _animate = false;

  @override
  void didUpdateWidget(BuildingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tier != widget.tier) {
      _animate = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = _animate;
    _animate = false;

    final color = BuildingConfig.colorForStat(widget.statKey);
    final progress = _calculateProgress();

    Widget building = GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // XP progress ring
            SizedBox(
              width: 110,
              height: 110,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            // Building image or placeholder
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color.withValues(alpha: widget.isGhost ? 0.35 : 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: widget.isGhost ? 0.2 : 1.0),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder base
                  Center(
                    child: Text(
                      '${widget.statKey.toUpperCase()}\nT${widget.tier}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Asset overlay
                  Image.asset(
                    'assets/compound/${widget.statKey}_t${widget.tier}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // Level badge
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  'Lv${widget.level}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Notification dot
            if (widget.hasPendingQuests && !widget.isGhost)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (shouldAnimate) {
      // Glow overlay
      building = Stack(
        alignment: Alignment.center,
        children: [
          building,
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          )
              .animate()
              .fade(duration: 200.ms, begin: 0, end: 1)
              .then()
              .fade(duration: 300.ms, begin: 1, end: 0),
        ],
      );

      // Scale pulse
      building = building
          .animate()
          .scale(duration: 250.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2))
          .then()
          .scale(duration: 250.ms, begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0));
    }

    return building;
  }

  double _calculateProgress() {
    if (widget.level == 1) {
      return widget.currentXp / XpConfig.xpForLevel(2);
    }
    final currentLevelBase = XpConfig.xpForLevel(widget.level);
    final nextLevelBase = XpConfig.xpForLevel(widget.level + 1);
    final xpInLevel = widget.currentXp - currentLevelBase;
    final xpNeeded = nextLevelBase - currentLevelBase;
    return xpInLevel / xpNeeded;
  }
}
