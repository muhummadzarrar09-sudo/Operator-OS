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
      duration: const Duration(seconds: 14),
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
  void dispose() {
    _ambientController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _centerView() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final size = renderObject.size;
    if (size.isEmpty) return;

    final focus = _computeCentroid();
    final scale = _initialScaleFor(size);

    final matrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale)
      ..translate(-focus.dx, -focus.dy);

    _controller.value = matrix;
  }

  void _zoomBy(double factor) {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final viewportCenter = renderObject.size.center(Offset.zero);
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(0.25, 2.4).toDouble();
    final sceneCenter = _controller.toScene(viewportCenter);

    final matrix = Matrix4.identity()
      ..translate(viewportCenter.dx, viewportCenter.dy)
      ..scale(nextScale)
      ..translate(-sceneCenter.dx, -sceneCenter.dy);

    _controller.value = matrix;
  }

  double _initialScaleFor(Size viewport) {
    final widthScale = viewport.width / (BuildingConfig.worldWidth * 0.62);
    final heightScale = viewport.height / (BuildingConfig.worldHeight * 0.62);
    return math.min(widthScale, heightScale).clamp(0.34, 0.66).toDouble();
  }

  Offset _computeCentroid() {
    final positions = widget.stats
        .map((stat) => BuildingConfig.buildingPositions[stat.statKey])
        .whereType<Offset>()
        .toList();

    if (positions.isEmpty) {
      return const Offset(
        BuildingConfig.worldWidth / 2,
        BuildingConfig.worldHeight / 2,
      );
    }

    double sumX = 0;
    double sumY = 0;
    for (final pos in positions) {
      sumX += pos.dx;
      sumY += pos.dy;
    }
    return Offset(sumX / positions.length, sumY / positions.length);
  }

  @override
  Widget build(BuildContext context) {
    final rawDaysSinceInstall = DateTime.now().difference(widget.installDate).inDays;
    final daysSinceInstall = math.max(0, rawDaysSinceInstall);
    final pendingByStat = <String, AsyncValue<List<Quest>>>{};

    for (final stat in widget.stats) {
      pendingByStat[stat.statKey] = ref.watch(
        questsByDomainStreamProvider(stat.statKey),
      );
    }

    final entities = _buildWorldEntities(
      pendingByStat: pendingByStat,
      daysSinceInstall: daysSinceInstall,
    );
    final totalXp = widget.stats.fold<int>(0, (sum, stat) => sum + stat.currentXp);
    final compoundLevel = widget.stats.isEmpty
        ? 1
        : (widget.stats.fold<int>(0, (sum, stat) => sum + stat.level) / widget.stats.length).floor();
    final activeMissions = pendingByStat.values.fold<int>(0, (sum, pending) {
      return sum + pending.when(
        data: (quests) => quests.length,
        loading: () => 0,
        error: (_, __) => 0,
      );
    });

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OperatorPalette.voidBlack,
                  OperatorPalette.nightNavy,
                  Color(0xFF071209),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            clipBehavior: Clip.none,
            boundaryMargin: const EdgeInsets.all(700),
            minScale: 0.25,
            maxScale: 2.4,
            child: SizedBox(
              width: BuildingConfig.worldWidth,
              height: BuildingConfig.worldHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CompoundTerrainPainter(),
                      ),
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
                  painter: _AtmospherePainter(_ambientController.value),
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
              campaignLabel: 'Compound Live',
              councilLabel: 'Pinch + drag',
              compact: true,
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 14,
          child: SafeArea(
            top: false,
            child: _WorldCameraControls(
              onZoomIn: () => _zoomBy(1.18),
              onZoomOut: () => _zoomBy(0.84),
              onReset: _centerView,
            ),
          ),
        ),
      ],
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

      final tier = XpConfig.tierForLevel(stat.level);
      final pendingAsync = pendingByStat[stat.statKey];
      final hasPending = pendingAsync?.when(
            data: (quests) => quests.isNotEmpty,
            loading: () => false,
            error: (_, __) => false,
          ) ??
          false;

      final ghostTier = PaceConfig.paceTierForStat(stat.statKey, daysSinceInstall);
      final ghostLevel = PaceConfig.paceLevelForStat(stat.statKey, daysSinceInstall);
      final ghostAnchor = BuildingConfig.ghostAnchorFor(anchor);

      entities.add(
        _WorldEntity(
          anchor: ghostAnchor,
          sortY: ghostAnchor.dy - 0.5,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.46,
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
              MaterialPageRoute(
                builder: (_) => StatDetailScreen(statKey: stat.statKey),
              ),
            ),
          ),
        ),
      );
    }

    entities.sort((a, b) {
      final yCompare = a.sortY.compareTo(b.sortY);
      if (yCompare != 0) return yCompare;
      return a.anchor.dx.compareTo(b.anchor.dx);
    });
    return entities;
  }
}

class _WorldEntity {
  final Offset anchor;
  final double sortY;
  final Widget child;

  const _WorldEntity({
    required this.anchor,
    required this.sortY,
    required this.child,
  });
}

class _WorldCameraControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _WorldCameraControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OperatorPalette.panelDark.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OperatorPalette.borderDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassIconButton(
              icon: Icons.remove,
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
            ),
            const SizedBox(width: 6),
            _GlassIconButton(
              icon: Icons.my_location,
              tooltip: 'Center compound',
              onPressed: onReset,
              highlighted: true,
            ),
            const SizedBox(width: 6),
            _GlassIconButton(
              icon: Icons.add,
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? OperatorPalette.parchmentGold : OperatorPalette.hologramBlue;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: highlighted ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final double progress;

  const _AtmospherePainter(this.progress);

  static const List<Offset> _particles = [
    Offset(0.10, 0.72),
    Offset(0.18, 0.38),
    Offset(0.26, 0.82),
    Offset(0.34, 0.28),
    Offset(0.46, 0.66),
    Offset(0.58, 0.46),
    Offset(0.70, 0.76),
    Offset(0.82, 0.34),
    Offset(0.92, 0.62),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final hazePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.18 + math.sin(progress * math.pi * 2) * 0.08, -0.28),
        radius: 1.2,
        colors: [
          OperatorPalette.torchOrange.withValues(alpha: 0.08),
          OperatorPalette.hologramBlue.withValues(alpha: 0.025),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, hazePaint);

    for (int i = 0; i < _particles.length; i++) {
      final seed = _particles[i];
      final wave = (progress + i * 0.137) % 1.0;
      final drift = math.sin((progress * math.pi * 2) + i) * 14;
      final pos = Offset(
        seed.dx * size.width + drift,
        seed.dy * size.height - wave * 54,
      );
      final pulse = 0.45 + 0.55 * math.sin((progress * math.pi * 2) + i * 1.7).abs();
      final radius = 1.8 + pulse * 2.6;
      final paint = Paint()
        ..color = (i.isEven ? OperatorPalette.torchOrange : OperatorPalette.hologramBlue)
            .withValues(alpha: 0.15 + pulse * 0.23)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CompoundTerrainPainter extends CustomPainter {
  static const Offset _mapCenter = Offset(BuildingConfig.worldWidth / 2, 820);
  static const Offset _plazaCenter = Offset(1070, 820);
  static const double _mapRadiusX = 900;
  static const double _mapRadiusY = 520;
  static const double _edgeDrop = 145;
  static const double _tileWidth = 128;
  static const double _tileHeight = 64;

  const _CompoundTerrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final top = _diamond(_mapCenter, _mapRadiusX, _mapRadiusY);
    final bottomCenter = _mapCenter.translate(0, _edgeDrop);
    final bottom = _diamond(bottomCenter, _mapRadiusX, _mapRadiusY);

    _paintOuterGlow(canvas, bottom);
    _paintIslandSides(canvas, bottom);
    _paintTopTerrain(canvas, top);

    canvas.save();
    canvas.clipPath(top);
    _paintTileGrid(canvas, top.getBounds());
    _paintRoads(canvas);
    _paintPlaza(canvas);
    _paintResourceProps(canvas);
    canvas.restore();

    _paintWalls(canvas, top);
    _paintCornerTowers(canvas);
  }

  void _paintOuterGlow(Canvas canvas, Path bottom) {
    canvas.drawPath(
      bottom.shift(const Offset(0, 24)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
  }

  void _paintIslandSides(Canvas canvas, Path bottom) {
    final leftSide = Path()
      ..moveTo(_mapCenter.dx - _mapRadiusX, _mapCenter.dy)
      ..lineTo(_mapCenter.dx, _mapCenter.dy + _mapRadiusY)
      ..lineTo(_mapCenter.dx, _mapCenter.dy + _mapRadiusY + _edgeDrop)
      ..lineTo(_mapCenter.dx - _mapRadiusX, _mapCenter.dy + _edgeDrop)
      ..close();
    final rightSide = Path()
      ..moveTo(_mapCenter.dx + _mapRadiusX, _mapCenter.dy)
      ..lineTo(_mapCenter.dx, _mapCenter.dy + _mapRadiusY)
      ..lineTo(_mapCenter.dx, _mapCenter.dy + _mapRadiusY + _edgeDrop)
      ..lineTo(_mapCenter.dx + _mapRadiusX, _mapCenter.dy + _edgeDrop)
      ..close();

    canvas.drawPath(leftSide, Paint()..color = const Color(0xFF234C25));
    canvas.drawPath(rightSide, Paint()..color = const Color(0xFF173719));
    canvas.drawPath(
      bottom,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.black.withValues(alpha: 0.22),
    );
  }

  void _paintTopTerrain(Canvas canvas, Path top) {
    final bounds = top.getBounds();
    final terrainPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4E8E3F),
          Color(0xFF2D6B31),
          Color(0xFF1F5025),
        ],
      ).createShader(bounds);

    canvas.drawPath(top, terrainPaint);
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = const Color(0xFF6E8A45).withValues(alpha: 0.55),
    );
  }

  void _paintTileGrid(Canvas canvas, Rect bounds) {
    final fillA = Paint()..color = Colors.white.withValues(alpha: 0.018);
    final fillB = Paint()..color = Colors.black.withValues(alpha: 0.018);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.08);

    for (int row = -18; row <= 18; row++) {
      for (int col = -18; col <= 18; col++) {
        final center = Offset(
          _mapCenter.dx + (col - row) * _tileWidth / 2,
          _mapCenter.dy + (col + row) * _tileHeight / 2,
        );
        final tile = _diamond(center, _tileWidth / 2, _tileHeight / 2);
        if (!tile.getBounds().overlaps(bounds)) continue;
        canvas.drawPath(tile, (row + col).isEven ? fillA : fillB);
        canvas.drawPath(tile, stroke);
      }
    }
  }

  void _paintRoads(Canvas canvas) {
    final roadBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 54
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF6B4A2F).withValues(alpha: 0.78);
    final roadTop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFC19A5B).withValues(alpha: 0.58);

    for (final anchor in BuildingConfig.buildingPositions.values) {
      final midpoint = Offset(
        (_plazaCenter.dx + anchor.dx) / 2,
        (_plazaCenter.dy + anchor.dy) / 2 - 30,
      );
      final path = Path()
        ..moveTo(_plazaCenter.dx, _plazaCenter.dy)
        ..quadraticBezierTo(midpoint.dx, midpoint.dy, anchor.dx, anchor.dy);
      canvas.drawPath(path, roadBase);
      canvas.drawPath(path, roadTop);
    }
  }

  void _paintPlaza(Canvas canvas) {
    final plazaBase = _diamond(_plazaCenter, 190, 92);
    final plazaInner = _diamond(_plazaCenter, 128, 58);

    canvas.drawPath(
      plazaBase,
      Paint()..color = const Color(0xFF4D3D31).withValues(alpha: 0.92),
    );
    canvas.drawPath(
      plazaInner,
      Paint()..color = const Color(0xFF9B7A4E).withValues(alpha: 0.8),
    );
    canvas.drawPath(
      plazaBase,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _paintResourceProps(Canvas canvas) {
    const trees = [
      Offset(440, 650),
      Offset(520, 560),
      Offset(1660, 700),
      Offset(1540, 520),
      Offset(520, 1080),
      Offset(1520, 1210),
      Offset(720, 1280),
      Offset(1780, 910),
    ];
    const rocks = [
      Offset(710, 485),
      Offset(1340, 470),
      Offset(410, 830),
      Offset(1640, 1010),
      Offset(1010, 1290),
      Offset(1360, 1295),
    ];
    const torches = [
      Offset(930, 755),
      Offset(1210, 755),
      Offset(930, 885),
      Offset(1210, 885),
      Offset(700, 720),
      Offset(1450, 830),
    ];
    const banners = [
      Offset(970, 665),
      Offset(1170, 675),
      Offset(620, 990),
      Offset(1500, 1030),
    ];

    for (final tree in trees) {
      _paintPineTree(canvas, tree);
    }
    for (final rock in rocks) {
      _paintRock(canvas, rock);
    }
    for (final torch in torches) {
      _paintTorch(canvas, torch);
    }
    for (int i = 0; i < banners.length; i++) {
      _paintBanner(canvas, banners[i], i.isEven ? OperatorPalette.torchOrange : OperatorPalette.hologramBlue);
    }
  }

  void _paintPineTree(Canvas canvas, Offset base) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.22);
    final trunk = Paint()..color = const Color(0xFF5A351E);
    final leafDark = Paint()..color = const Color(0xFF133D22);
    final leafLight = Paint()..color = const Color(0xFF2F7B3D);

    canvas.drawOval(Rect.fromCenter(center: base.translate(0, 8), width: 58, height: 22), shadow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -12), width: 13, height: 36), const Radius.circular(4)),
      trunk,
    );

    for (int i = 0; i < 3; i++) {
      final y = base.dy - 22 - i * 24;
      final halfWidth = 34.0 - i * 5;
      final canopy = Path()
        ..moveTo(base.dx, y - 38)
        ..lineTo(base.dx + halfWidth, y + 8)
        ..lineTo(base.dx - halfWidth, y + 8)
        ..close();
      canvas.drawPath(canopy, i.isEven ? leafLight : leafDark);
    }
  }

  void _paintRock(Canvas canvas, Offset base) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final rockPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9CA3AF), Color(0xFF4B5563)],
      ).createShader(Rect.fromCenter(center: base, width: 72, height: 48));
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.18);

    canvas.drawOval(Rect.fromCenter(center: base.translate(0, 14), width: 72, height: 26), shadow);
    final rock = Path()
      ..moveTo(base.dx - 32, base.dy + 10)
      ..lineTo(base.dx - 18, base.dy - 24)
      ..lineTo(base.dx + 10, base.dy - 32)
      ..lineTo(base.dx + 36, base.dy - 4)
      ..lineTo(base.dx + 22, base.dy + 18)
      ..lineTo(base.dx - 12, base.dy + 24)
      ..close();
    canvas.drawPath(rock, rockPaint);
    canvas.drawCircle(base.translate(-8, -13), 5, highlight);
  }

  void _paintTorch(Canvas canvas, Offset base) {
    final pole = Paint()
      ..color = const Color(0xFF3A2417)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final flame = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.78),
          OperatorPalette.torchOrange.withValues(alpha: 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: base.translate(0, -34), width: 62, height: 62));

    canvas.drawLine(base, base.translate(0, -34), pole);
    canvas.drawCircle(base.translate(0, -38), 24, flame);
    canvas.drawCircle(base.translate(0, -39), 6, Paint()..color = const Color(0xFFFFF2A8));
  }

  void _paintBanner(Canvas canvas, Offset base, Color color) {
    final pole = Paint()
      ..color = const Color(0xFF33251B)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base.translate(0, -58), pole);

    final flag = Path()
      ..moveTo(base.dx, base.dy - 58)
      ..lineTo(base.dx + 42, base.dy - 48)
      ..lineTo(base.dx + 30, base.dy - 31)
      ..lineTo(base.dx, base.dy - 38)
      ..close();
    canvas.drawPath(flag, Paint()..color = color.withValues(alpha: 0.84));
    canvas.drawPath(
      flag,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  void _paintWalls(Canvas canvas, Path top) {
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF2E2F28).withValues(alpha: 0.92),
    );
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFD0B36A).withValues(alpha: 0.5),
    );
  }

  void _paintCornerTowers(Canvas canvas) {
    final corners = [
      Offset(_mapCenter.dx, _mapCenter.dy - _mapRadiusY),
      Offset(_mapCenter.dx + _mapRadiusX, _mapCenter.dy),
      Offset(_mapCenter.dx, _mapCenter.dy + _mapRadiusY),
      Offset(_mapCenter.dx - _mapRadiusX, _mapCenter.dy),
    ];

    for (final corner in corners) {
      _paintCornerTower(canvas, corner);
    }
  }

  void _paintCornerTower(Canvas canvas, Offset base) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.26);
    final side = Paint()..color = const Color(0xFF22251F);
    final face = Paint()..color = const Color(0xFF34382D);
    final trim = Paint()..color = const Color(0xFFD0B36A).withValues(alpha: 0.56);

    canvas.drawOval(Rect.fromCenter(center: base.translate(0, 26), width: 88, height: 34), shadow);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: base.translate(0, -8), width: 54, height: 72),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, face);

    final rightFace = Path()
      ..moveTo(base.dx + 27, base.dy - 42)
      ..lineTo(base.dx + 43, base.dy - 28)
      ..lineTo(base.dx + 43, base.dy + 20)
      ..lineTo(base.dx + 27, base.dy + 28)
      ..close();
    canvas.drawPath(rightFace, side);

    final roof = Path()
      ..moveTo(base.dx, base.dy - 72)
      ..lineTo(base.dx + 42, base.dy - 42)
      ..lineTo(base.dx, base.dy - 24)
      ..lineTo(base.dx - 42, base.dy - 42)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF5A3321));
    canvas.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = trim.color,
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
  bool shouldRepaint(covariant _CompoundTerrainPainter oldDelegate) => false;
}
