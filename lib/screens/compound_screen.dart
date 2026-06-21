import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/data/database.dart';
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
    );
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
    // The base map is a square rendered asset. Use an aggressive opening scale
    // so the island feels like a game map, not a tiny board in empty space.
    final widthScale = viewport.width / (BuildingConfig.worldWidth * 0.70);
    final heightScale = viewport.height / (BuildingConfig.worldHeight * 0.74);
    return math.max(widthScale, heightScale).clamp(0.52, 0.90).toDouble();
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
                          child: _CompoundBaseMap(),
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

class _CompoundBaseMap extends StatelessWidget {
  const _CompoundBaseMap();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/compound/compound_base.png',
      width: BuildingConfig.worldWidth,
      height: BuildingConfig.worldHeight,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
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
