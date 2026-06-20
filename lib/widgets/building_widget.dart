import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    Widget building = _BuildingHitRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: SizedBox(
          width: BuildingConfig.buildingSpriteWidth,
          height: BuildingConfig.buildingSpriteHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 42,
                child: _GroundShadow(color: color, isGhost: widget.isGhost),
              ),
              Positioned.fill(
                bottom: 34,
                child: _BuildingSprite(
                  statKey: widget.statKey,
                  tier: widget.tier,
                  color: color,
                  isGhost: widget.isGhost,
                ),
              ),
              Positioned(
                left: 34,
                right: 34,
                bottom: 4,
                child: _BuildingPlate(
                  statKey: widget.statKey,
                  level: widget.level,
                  tier: widget.tier,
                  progress: progress,
                  color: color,
                  isGhost: widget.isGhost,
                ),
              ),
              if (widget.hasPendingQuests && !widget.isGhost)
                Positioned(
                  top: 36,
                  right: 42,
                  child: _QuestBeacon(color: color),
                ),
            ],
          ),
        ),
      ),
    );

    if (shouldAnimate) {
      building = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          building,
          Positioned(
            top: 20,
            child: IgnorePointer(
              child: Container(
                width: BuildingConfig.buildingSpriteWidth * 0.82,
                height: BuildingConfig.buildingSpriteHeight * 0.72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.55),
                      blurRadius: 36,
                      spreadRadius: 14,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fade(duration: 200.ms, begin: 0, end: 1)
                  .then()
                  .fade(duration: 300.ms, begin: 1, end: 0),
            ),
          ),
        ],
      )
          .animate()
          .scale(duration: 250.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.12, 1.12))
          .then()
          .scale(duration: 250.ms, begin: const Offset(1.12, 1.12), end: const Offset(1.0, 1.0));
    }

    return building;
  }

  double _calculateProgress() {
    if (widget.level == 1) {
      final raw = widget.currentXp / XpConfig.xpForLevel(2);
      return raw.clamp(0.0, 1.0).toDouble();
    }
    final currentLevelBase = XpConfig.xpForLevel(widget.level);
    final nextLevelBase = XpConfig.xpForLevel(widget.level + 1);
    final xpInLevel = widget.currentXp - currentLevelBase;
    final xpNeeded = nextLevelBase - currentLevelBase;
    final raw = xpInLevel / xpNeeded;
    return raw.clamp(0.0, 1.0).toDouble();
  }
}

class _BuildingHitRegion extends SingleChildRenderObjectWidget {
  const _BuildingHitRegion({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _BuildingHitRenderBox();
  }
}

class _BuildingHitRenderBox extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_containsVisibleSprite(position)) return false;
    return super.hitTest(result, position: position);
  }

  bool _containsVisibleSprite(Offset position) {
    if (size.isEmpty) return false;

    final x = position.dx / size.width;
    final y = position.dy / size.height;
    if (x < 0 || x > 1 || y < 0.04 || y > 0.98) return false;

    // Tall isometric sprites have a narrow roof, a wide body, then a base
    // diamond. This approximation keeps taps feeling accurate without needing
    // per-pixel alpha hit-testing for every PNG.
    final roofAndBodyHalfWidth = switch (y) {
      < 0.18 => 0.12,
      < 0.34 => 0.18 + (y - 0.18) * 0.95,
      < 0.72 => 0.34,
      _ => 0.24,
    };
    final insideVerticalMass = (x - 0.5).abs() <= roofAndBodyHalfWidth;

    final baseDx = ((x - 0.5).abs()) / 0.40;
    final baseDy = ((y - 0.80).abs()) / 0.18;
    final insideBaseDiamond = baseDx + baseDy <= 1.0;

    final insideNamePlate = y >= 0.78 && y <= 0.98 && x >= 0.14 && x <= 0.86;

    return insideVerticalMass || insideBaseDiamond || insideNamePlate;
  }
}

class _BuildingSprite extends StatelessWidget {
  final String statKey;
  final int tier;
  final Color color;
  final bool isGhost;

  const _BuildingSprite({
    required this.statKey,
    required this.tier,
    required this.color,
    required this.isGhost,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/compound/${statKey}_t$tier.png',
      alignment: Alignment.bottomCenter,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: isGhost ? Colors.white.withValues(alpha: 0.72) : null,
      colorBlendMode: isGhost ? BlendMode.modulate : null,
      errorBuilder: (_, __, ___) => Center(
        child: _FallbackBuilding(
          statKey: statKey,
          tier: tier,
          color: color,
          isGhost: isGhost,
        ),
      ),
    );
  }
}

class _GroundShadow extends StatelessWidget {
  final Color color;
  final bool isGhost;

  const _GroundShadow({required this.color, required this.isGhost});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: RadialGradient(
          colors: [
            Colors.black.withValues(alpha: isGhost ? 0.16 : 0.36),
            color.withValues(alpha: isGhost ? 0.05 : 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _BuildingPlate extends StatelessWidget {
  final String statKey;
  final int level;
  final int tier;
  final double progress;
  final Color color;
  final bool isGhost;

  const _BuildingPlate({
    required this.statKey,
    required this.level,
    required this.tier,
    required this.progress,
    required this.color,
    required this.isGhost,
  });

  @override
  Widget build(BuildContext context) {
    final alpha = isGhost ? 0.58 : 0.92;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isGhost ? 0.34 : 0.78),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isGhost ? 0.12 : 0.26),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    statKey.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isGhost ? Colors.white70 : Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isGhost ? 'PACE T$tier' : 'Lv$level T$tier',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: isGhost ? 1 : progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(
                  isGhost ? Colors.white.withValues(alpha: 0.48) : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestBeacon extends StatelessWidget {
  final Color color;

  const _QuestBeacon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.redAccent,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _FallbackBuilding extends StatelessWidget {
  final String statKey;
  final int tier;
  final Color color;
  final bool isGhost;

  const _FallbackBuilding({
    required this.statKey,
    required this.tier,
    required this.color,
    required this.isGhost,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      height: 154,
      child: CustomPaint(
        painter: _FallbackBuildingPainter(color: color, tier: tier, isGhost: isGhost),
        child: Center(
          child: Text(
            '${statKey.toUpperCase()}\nT$tier',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackBuildingPainter extends CustomPainter {
  final Color color;
  final int tier;
  final bool isGhost;

  const _FallbackBuildingPainter({
    required this.color,
    required this.tier,
    required this.isGhost,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = color.withValues(alpha: isGhost ? 0.28 : 0.82);
    final sidePaint = Paint()..color = Color.lerp(color, Colors.black, 0.32)!.withValues(alpha: isGhost ? 0.24 : 0.9);
    final roofPaint = Paint()..color = Color.lerp(color, Colors.white, 0.16)!.withValues(alpha: isGhost ? 0.3 : 1);

    final base = Path()
      ..moveTo(size.width * 0.50, size.height * 0.66)
      ..lineTo(size.width * 0.82, size.height * 0.80)
      ..lineTo(size.width * 0.50, size.height * 0.94)
      ..lineTo(size.width * 0.18, size.height * 0.80)
      ..close();
    canvas.drawPath(base, sidePaint);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.34, size.width * 0.50, size.height * 0.46),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, basePaint);

    final roof = Path()
      ..moveTo(size.width * 0.50, size.height * 0.08)
      ..lineTo(size.width * 0.82, size.height * 0.40)
      ..lineTo(size.width * 0.18, size.height * 0.40)
      ..close();
    canvas.drawPath(roof, roofPaint);

    if (tier >= 3) {
      final tower = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.20, size.width * 0.16, size.height * 0.28),
        const Radius.circular(8),
      );
      canvas.drawRRect(tower, basePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FallbackBuildingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.tier != tier || oldDelegate.isGhost != isGhost;
  }
}
