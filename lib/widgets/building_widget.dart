import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';

class BuildingWidget extends StatefulWidget {
  final String statKey;
  final int level;
  final int currentXp;
  final int tier;
  final bool hasPendingQuests;
  final bool isBehindPace;
  final bool isGhost;
  final VoidCallback? onTap;

  const BuildingWidget({
    required this.statKey,
    required this.level,
    required this.currentXp,
    required this.tier,
    this.hasPendingQuests = false,
    this.isBehindPace = false,
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
        width: 132,
        height: 142,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 8,
              child: Container(
                width: 106,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: widget.isGhost ? 0.10 : 0.26),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: widget.isGhost ? 0.16 : 0.28),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 118,
              height: 118,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: OperatorPalette.borderDim.withValues(alpha: 0.55),
                valueColor: AlwaysStoppedAnimation(
                  widget.isGhost ? OperatorPalette.hologramBlue.withValues(alpha: 0.55) : color,
                ),
              ),
            ),
            _BuildingShell(
              statKey: widget.statKey,
              tier: widget.tier,
              color: color,
              isGhost: widget.isGhost,
              isBehindPace: widget.isBehindPace,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: OperatorPalette.voidBlack.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.isGhost ? OperatorPalette.hologramBlue : OperatorPalette.parchmentGold,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.isGhost ? 'Pace ${widget.level}' : 'Lv ${widget.level}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: OperatorPalette.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (widget.hasPendingQuests && !widget.isGhost)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: OperatorPalette.warningAmber,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: OperatorPalette.voidBlack, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: OperatorPalette.warningAmber.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Text(
                    'MISSION',
                    style: TextStyle(
                      fontSize: 8,
                      color: OperatorPalette.voidBlack,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            if (widget.isBehindPace && !widget.isGhost)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: OperatorPalette.hologramBlue.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    border: Border.all(color: OperatorPalette.voidBlack, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: OperatorPalette.hologramBlue.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.trending_up, size: 11, color: OperatorPalette.voidBlack),
                ),
              ),
          ],
        ),
      ),
    );

    if (shouldAnimate) {
      building = Stack(
        alignment: Alignment.center,
        children: [
          building,
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: OperatorPalette.parchmentGold.withValues(alpha: 0.6),
                  blurRadius: 34,
                  spreadRadius: 12,
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

class _BuildingShell extends StatelessWidget {
  final String statKey;
  final int tier;
  final Color color;
  final bool isGhost;
  final bool isBehindPace;

  const _BuildingShell({
    required this.statKey,
    required this.tier,
    required this.color,
    required this.isGhost,
    required this.isBehindPace,
  });

  @override
  Widget build(BuildContext context) {
    final shellColor = isGhost ? OperatorPalette.hologramBlue : color;
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shellColor.withValues(alpha: isGhost ? 0.18 : 0.72),
            OperatorPalette.panelRaised.withValues(alpha: isGhost ? 0.12 : 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(_radiusForTier(tier)),
        border: Border.all(
          color: isBehindPace && !isGhost
              ? OperatorPalette.hologramBlue.withValues(alpha: 0.85)
              : shellColor.withValues(alpha: isGhost ? 0.55 : 0.95),
          width: isBehindPace && !isGhost ? 2.5 : (isGhost ? 1.5 : 2),
        ),
        boxShadow: [
          BoxShadow(
            color: shellColor.withValues(alpha: isGhost ? 0.18 : 0.30),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _BuildingPatternPainter(color: shellColor, tier: tier, isGhost: isGhost),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForStat(statKey), color: OperatorPalette.textPrimary, size: 28),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    OperatorCopy.shortStatLabel(statKey).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: OperatorPalette.textPrimary,
                    ),
                  ),
                ),
                Text(
                  'T$tier',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isGhost ? OperatorPalette.hologramBlue : OperatorPalette.parchmentGold,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/compound/${statKey}_t$tier.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          if (isGhost)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: OperatorPalette.hologramBlue.withValues(alpha: 0.08),
                  border: Border.all(color: OperatorPalette.hologramBlue.withValues(alpha: 0.28)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _radiusForTier(int tier) {
    return switch (tier) {
      1 => 18,
      2 => 15,
      3 => 12,
      _ => 10,
    };
  }

  IconData _iconForStat(String statKey) {
    return switch (statKey) {
      'forge' => Icons.local_fire_department,
      'academy' => Icons.school,
      'leverage' => Icons.handshake,
      'presence' => Icons.campaign,
      'craft' => Icons.brush,
      'vitality' => Icons.fitness_center,
      'capital' => Icons.account_balance,
      'clarity' => Icons.visibility,
      _ => Icons.home_work,
    };
  }
}

class _BuildingPatternPainter extends CustomPainter {
  final Color color;
  final int tier;
  final bool isGhost;

  _BuildingPatternPainter({required this.color, required this.tier, required this.isGhost});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isGhost ? 0.18 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final roofHeight = size.height * (0.22 + tier * 0.025);
    final roof = Path()
      ..moveTo(size.width * 0.14, roofHeight)
      ..lineTo(size.width * 0.50, size.height * 0.07)
      ..lineTo(size.width * 0.86, roofHeight);
    canvas.drawPath(roof, paint);

    for (int i = 0; i < tier; i++) {
      final y = size.height * (0.70 - i * 0.12);
      canvas.drawLine(Offset(size.width * 0.22, y), Offset(size.width * 0.78, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BuildingPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.tier != tier || oldDelegate.isGhost != isGhost;
  }
}
