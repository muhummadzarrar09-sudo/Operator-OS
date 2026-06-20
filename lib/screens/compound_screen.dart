import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/install_date_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/providers/user_initializer.dart';
import 'package:operator_os/screens/stat_detail_screen.dart';
import 'package:operator_os/widgets/building_widget.dart';
import 'package:operator_os/widgets/operator_card.dart';
import 'package:operator_os/widgets/operator_world_hud.dart';

class CompoundScreen extends ConsumerWidget {
  const CompoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userInitializerProvider);
    final statsAsync = ref.watch(statsStreamProvider);
    final installDateAsync = ref.watch(installDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('The Compound')),
      body: statsAsync.when(
        data: (stats) {
          return installDateAsync.when(
            data: (installDate) => _CompoundView(
              stats: stats,
              installDate: installDate,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Install date error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Stats error: $err')),
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: () => _showDebugXpDialog(context, ref),
              child: const Icon(Icons.bug_report),
            )
          : null,
    );
  }

  void _showDebugXpDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug: Add XP'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: StatKey.values.map((key) {
              return ListTile(
                title: Text(key.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _addXp(ref, key.name, 500),
                      child: const Text('+500'),
                    ),
                    TextButton(
                      onPressed: () => _addXp(ref, key.name, 2000),
                      child: const Text('+2K'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addXp(WidgetRef ref, String statKey, int xp) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref.read(statsRepositoryProvider).addXp(userId, statKey, xp);
  }
}

class _CompoundView extends ConsumerStatefulWidget {
  final List<Stat> stats;
  final DateTime installDate;

  const _CompoundView({required this.stats, required this.installDate});

  @override
  ConsumerState<_CompoundView> createState() => _CompoundViewState();
}

class _CompoundViewState extends ConsumerState<_CompoundView>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _ambientController;
  bool _didCenter = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didCenter) {
      _didCenter = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
    }
  }

  @override
  void didUpdateWidget(covariant _CompoundView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats.isEmpty && widget.stats.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerView());
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _centerView() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || renderObject.size.isEmpty) return;

    final viewport = renderObject.size;
    final focus = _computeCentroid();
    final scale = _initialScaleFor(viewport);

    _controller.value = Matrix4.identity()
      ..translate(viewport.width / 2, viewport.height / 2)
      ..scale(scale)
      ..translate(-focus.dx, -focus.dy);
  }

  void _zoomBy(double factor) {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || renderObject.size.isEmpty) return;

    final viewportCenter = renderObject.size.center(Offset.zero);
    final sceneCenter = _controller.toScene(viewportCenter);
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(0.32, 1.9).toDouble();

    _controller.value = Matrix4.identity()
      ..translate(viewportCenter.dx, viewportCenter.dy)
      ..scale(nextScale)
      ..translate(-sceneCenter.dx, -sceneCenter.dy);
  }

  double _initialScaleFor(Size viewport) {
    final widthScale = viewport.width / (BuildingConfig.worldWidth * 0.82);
    final heightScale = viewport.height / (BuildingConfig.worldHeight * 0.78);
    return math.min(widthScale, heightScale).clamp(0.38, 0.78).toDouble();
  }

  Offset _computeCentroid() {
    final positions = widget.stats
        .map((stat) => BuildingConfig.buildingPositions[stat.statKey])
        .whereType<Offset>()
        .toList();
    if (positions.isEmpty) {
      return const Offset(BuildingConfig.worldWidth / 2, BuildingConfig.worldHeight / 2);
    }

    double x = 0;
    double y = 0;
    for (final position in positions) {
      x += position.dx;
      y += position.dy;
    }
    return Offset(x / positions.length, y / positions.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) {
      return const _CompoundEmptyState();
    }

    final daysSinceInstall = math.max(0, DateTime.now().difference(widget.installDate).inDays);
    final pendingByStat = <String, AsyncValue<List<Quest>>>{};
    for (final stat in widget.stats) {
      pendingByStat[stat.statKey] = ref.watch(questsByDomainStreamProvider(stat.statKey));
    }

    final entities = _buildWorldEntities(
      pendingByStat: pendingByStat,
      daysSinceInstall: daysSinceInstall,
    );
    final totalXp = widget.stats.fold<int>(0, (sum, stat) => sum + stat.currentXp);
    final compoundLevel = (widget.stats.fold<int>(0, (sum, stat) => sum + stat.level) / widget.stats.length).floor();
    final activeMissions = pendingByStat.values.fold<int>(0, (sum, pending) {
      return sum + pending.when(
        data: (quests) => quests.length,
        loading: () => 0,
        error: (_, __) => 0,
      );
    });

    return LayoutBuilder(
      builder: (context, _) {
        return Stack(
          children: [
            const Positioned.fill(child: _CompoundBackdrop()),
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                clipBehavior: Clip.hardEdge,
                boundaryMargin: const EdgeInsets.all(360),
                minScale: 0.32,
                maxScale: 1.9,
                child: SizedBox(
                  width: BuildingConfig.worldWidth,
                  height: BuildingConfig.worldHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(painter: _CompoundMapPainter()),
                        ),
                      ),
                      ...entities.map(
                        (entity) => Positioned(
                          left: entity.anchor.dx - BuildingConfig.buildingSpriteWidth / 2,
                          top: entity.anchor.dy - BuildingConfig.buildingAnchorYOffset,
                          child: RepaintBoundary(child: entity.child),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CompoundAtmospherePainter(_ambientController.value),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: SafeArea(
                bottom: false,
                child: OperatorWorldHud(
                  compoundLevel: compoundLevel,
                  totalXp: totalXp,
                  activeMissions: activeMissions,
                  campaignLabel: 'Live Base',
                  councilLabel: 'Drag / pinch',
                  compact: true,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: _CameraControls(
                  onZoomOut: () => _zoomBy(0.86),
                  onReset: _centerView,
                  onZoomIn: () => _zoomBy(1.16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_WorldEntity> _buildWorldEntities({
    required Map<String, AsyncValue<List<Quest>>> pendingByStat,
    required int daysSinceInstall,
  }) {
    final entities = <_WorldEntity>[];

    for (final stat in widget.stats) {
      final anchor = BuildingConfig.buildingPositions[stat.statKey];
      if (anchor == null) continue;

      final ghostAnchor = BuildingConfig.ghostAnchorFor(anchor);
      final ghostLevel = PaceConfig.paceLevelForStat(stat.statKey, daysSinceInstall);
      final ghostTier = PaceConfig.paceTierForStat(stat.statKey, daysSinceInstall);
      final tier = XpConfig.tierForLevel(stat.level);
      final hasPending = pendingByStat[stat.statKey]?.when(
            data: (quests) => quests.isNotEmpty,
            loading: () => false,
            error: (_, __) => false,
          ) ??
          false;

      entities.add(
        _WorldEntity(
          anchor: ghostAnchor,
          sortY: ghostAnchor.dy - 0.25,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.42,
              child: BuildingWidget(
                key: ValueKey('${stat.statKey}_ghost'),
                statKey: stat.statKey,
                level: ghostLevel,
                currentXp: 0,
                tier: ghostTier,
                isGhost: true,
              ),
            ),
          ),
        ),
      );

      entities.add(
        _WorldEntity(
          anchor: anchor,
          sortY: anchor.dy,
          child: BuildingWidget(
            key: ValueKey('${stat.statKey}_real'),
            statKey: stat.statKey,
            level: stat.level,
            currentXp: stat.currentXp,
            tier: tier,
            hasPendingQuests: hasPending,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StatDetailScreen(statKey: stat.statKey),
              ),
            ),
          ),
        ),
      );
    }

    entities.sort((a, b) {
      final byY = a.sortY.compareTo(b.sortY);
      if (byY != 0) return byY;
      return a.anchor.dx.compareTo(b.anchor.dx);
    });

    return entities;
  }
}

class _WorldEntity {
  final Offset anchor;
  final double sortY;
  final Widget child;

  const _WorldEntity({required this.anchor, required this.sortY, required this.child});
}

class _CompoundEmptyState extends StatelessWidget {
  const _CompoundEmptyState();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [OperatorPalette.voidBlack, OperatorPalette.nightNavy],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: OperatorCard(
            icon: Icons.construction,
            label: 'COMPOUND BOOTING',
            title: 'Your local base is being prepared.',
            body: 'If this stays here, enter Personal Mode again from the login screen. Supabase is not required for local mode.',
          ),
        ),
      ),
    );
  }
}

class _CompoundBackdrop extends StatelessWidget {
  const _CompoundBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF07101E),
            OperatorPalette.nightNavy,
            Color(0xFF071109),
          ],
        ),
      ),
    );
  }
}

class _CameraControls extends StatelessWidget {
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onZoomIn;

  const _CameraControls({
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: OperatorPalette.panelDark.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OperatorPalette.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CameraButton(icon: Icons.remove, tooltip: 'Zoom out', onTap: onZoomOut),
          const SizedBox(width: 6),
          _CameraButton(icon: Icons.my_location, tooltip: 'Center', onTap: onReset, primary: true),
          const SizedBox(width: 6),
          _CameraButton(icon: Icons.add, tooltip: 'Zoom in', onTap: onZoomIn),
        ],
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool primary;

  const _CameraButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = primary ? OperatorPalette.parchmentGold : OperatorPalette.hologramBlue;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: primary ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 42, height: 42, child: Icon(icon, color: color)),
        ),
      ),
    );
  }
}

class _CompoundMapPainter extends CustomPainter {
  static const Offset _center = Offset(BuildingConfig.worldWidth / 2, 650);
  static const double _radiusX = 730;
  static const double _radiusY = 430;
  static const double _drop = 110;
  static const double _tileW = 104;
  static const double _tileH = 52;

  const _CompoundMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final top = _diamond(_center, _radiusX, _radiusY);
    final bottom = _diamond(_center.translate(0, _drop), _radiusX, _radiusY);

    _paintShadow(canvas, bottom);
    _paintSides(canvas);
    _paintTop(canvas, top);

    canvas.save();
    canvas.clipPath(top);
    _paintGrid(canvas, top.getBounds());
    _paintRoads(canvas);
    _paintPlaza(canvas);
    _paintDecor(canvas);
    canvas.restore();

    _paintWall(canvas, top);
  }

  void _paintShadow(Canvas canvas, Path bottom) {
    canvas.drawPath(
      bottom.shift(const Offset(0, 18)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  void _paintSides(Canvas canvas) {
    final left = Path()
      ..moveTo(_center.dx - _radiusX, _center.dy)
      ..lineTo(_center.dx, _center.dy + _radiusY)
      ..lineTo(_center.dx, _center.dy + _radiusY + _drop)
      ..lineTo(_center.dx - _radiusX, _center.dy + _drop)
      ..close();
    final right = Path()
      ..moveTo(_center.dx + _radiusX, _center.dy)
      ..lineTo(_center.dx, _center.dy + _radiusY)
      ..lineTo(_center.dx, _center.dy + _radiusY + _drop)
      ..lineTo(_center.dx + _radiusX, _center.dy + _drop)
      ..close();

    canvas.drawPath(left, Paint()..color = const Color(0xFF284C27));
    canvas.drawPath(right, Paint()..color = const Color(0xFF183616));
  }

  void _paintTop(Canvas canvas, Path top) {
    final bounds = top.getBounds();
    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF569A46), Color(0xFF2E6B33), Color(0xFF1E4E25)],
        ).createShader(bounds),
    );
  }

  void _paintGrid(Canvas canvas, Rect bounds) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.075);
    final fillA = Paint()..color = Colors.white.withValues(alpha: 0.018);
    final fillB = Paint()..color = Colors.black.withValues(alpha: 0.018);

    for (int row = -16; row <= 16; row++) {
      for (int col = -16; col <= 16; col++) {
        final tileCenter = Offset(
          _center.dx + (col - row) * _tileW / 2,
          _center.dy + (col + row) * _tileH / 2,
        );
        final tile = _diamond(tileCenter, _tileW / 2, _tileH / 2);
        if (!tile.getBounds().overlaps(bounds)) continue;
        canvas.drawPath(tile, (row + col).isEven ? fillA : fillB);
        canvas.drawPath(tile, line);
      }
    }
  }

  void _paintRoads(Canvas canvas) {
    final roadBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 44
      ..color = const Color(0xFF654B33).withValues(alpha: 0.80);
    final roadTop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 24
      ..color = const Color(0xFFC09A5D).withValues(alpha: 0.62);

    for (final anchor in BuildingConfig.buildingPositions.values) {
      final control = Offset((_center.dx + anchor.dx) / 2, (_center.dy + anchor.dy) / 2 - 24);
      final path = Path()
        ..moveTo(_center.dx, _center.dy)
        ..quadraticBezierTo(control.dx, control.dy, anchor.dx, anchor.dy);
      canvas.drawPath(path, roadBase);
      canvas.drawPath(path, roadTop);
    }
  }

  void _paintPlaza(Canvas canvas) {
    final outer = _diamond(_center, 170, 82);
    final inner = _diamond(_center, 108, 50);
    canvas.drawPath(outer, Paint()..color = const Color(0xFF4B3A2E));
    canvas.drawPath(inner, Paint()..color = const Color(0xFF9D7A49));
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _paintDecor(Canvas canvas) {
    const trees = [
      Offset(430, 560),
      Offset(510, 800),
      Offset(1320, 570),
      Offset(1390, 840),
      Offset(650, 1030),
      Offset(1180, 1010),
    ];
    const stones = [
      Offset(690, 390),
      Offset(1120, 390),
      Offset(420, 690),
      Offset(1420, 710),
      Offset(870, 1040),
    ];
    const torches = [
      Offset(800, 590),
      Offset(1000, 590),
      Offset(800, 720),
      Offset(1000, 720),
    ];

    for (final tree in trees) {
      _paintTree(canvas, tree);
    }
    for (final stone in stones) {
      _paintStone(canvas, stone);
    }
    for (final torch in torches) {
      _paintTorch(canvas, torch);
    }
  }

  void _paintTree(Canvas canvas, Offset base) {
    canvas.drawOval(Rect.fromCenter(center: base.translate(0, 10), width: 54, height: 20), Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawRect(Rect.fromCenter(center: base.translate(0, -10), width: 10, height: 28), Paint()..color = const Color(0xFF58351E));
    for (int i = 0; i < 3; i++) {
      final y = base.dy - 22 - i * 22;
      final width = 34.0 - i * 5;
      final path = Path()
        ..moveTo(base.dx, y - 34)
        ..lineTo(base.dx + width, y + 7)
        ..lineTo(base.dx - width, y + 7)
        ..close();
      canvas.drawPath(path, Paint()..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF14532D));
    }
  }

  void _paintStone(Canvas canvas, Offset base) {
    canvas.drawOval(Rect.fromCenter(center: base.translate(0, 12), width: 58, height: 20), Paint()..color = Colors.black.withValues(alpha: 0.17));
    final path = Path()
      ..moveTo(base.dx - 26, base.dy + 9)
      ..lineTo(base.dx - 12, base.dy - 20)
      ..lineTo(base.dx + 14, base.dy - 24)
      ..lineTo(base.dx + 30, base.dy + 2)
      ..lineTo(base.dx + 16, base.dy + 18)
      ..lineTo(base.dx - 14, base.dy + 20)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF6B7280));
    canvas.drawCircle(base.translate(-6, -9), 4, Paint()..color = Colors.white.withValues(alpha: 0.18));
  }

  void _paintTorch(Canvas canvas, Offset base) {
    canvas.drawLine(
      base,
      base.translate(0, -28),
      Paint()
        ..color = const Color(0xFF3A2417)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      base.translate(0, -32),
      20,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.80),
            OperatorPalette.torchOrange.withValues(alpha: 0.86),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCenter(center: base.translate(0, -32), width: 46, height: 46)),
    );
  }

  void _paintWall(Canvas canvas, Path top) {
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 24
        ..color = const Color(0xFF2F332C),
    );
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 7
        ..color = OperatorPalette.parchmentGold.withValues(alpha: 0.48),
    );
  }

  Path _diamond(Offset center, double radiusX, double radiusY) {
    return Path()
      ..moveTo(center.dx, center.dy - radiusY)
      ..lineTo(center.dx + radiusX, center.dy)
      ..lineTo(center.dx, center.dy + radiusY)
      ..lineTo(center.dx - radiusX, center.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _CompoundMapPainter oldDelegate) => false;
}

class _CompoundAtmospherePainter extends CustomPainter {
  final double progress;

  const _CompoundAtmospherePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final haze = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.2 + math.sin(progress * math.pi * 2) * 0.08, -0.35),
        radius: 1.1,
        colors: [
          OperatorPalette.torchOrange.withValues(alpha: 0.06),
          OperatorPalette.hologramBlue.withValues(alpha: 0.018),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, haze);

    final spark = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int i = 0; i < 10; i++) {
      final phase = (progress + i * 0.11) % 1.0;
      final x = size.width * (((i * 23) % 100) / 100) + math.sin(progress * math.pi * 2 + i) * 16;
      final y = size.height * (0.9 - phase * 0.75);
      final pulse = math.sin(progress * math.pi * 2 + i).abs();
      spark.color = (i.isEven ? OperatorPalette.torchOrange : OperatorPalette.hologramBlue)
          .withValues(alpha: 0.10 + pulse * 0.18);
      canvas.drawCircle(Offset(x, y), 2.0 + pulse * 2.6, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _CompoundAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
