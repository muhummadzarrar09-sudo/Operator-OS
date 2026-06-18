import 'dart:math' as math;

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
import 'package:operator_os/screens/building_atlas_screen.dart';
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
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: const Text('The Compound'),
        actions: [
          IconButton(
            tooltip: 'Building Atlas',
            icon: const Icon(Icons.auto_awesome_mosaic_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BuildingAtlasScreen()),
            ),
          ),
        ],
      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDebugXpDialog(context, ref),
        icon: const Icon(Icons.fitness_center),
        label: const Text('Training'),
      ),
    );
  }

  void _showDebugXpDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Training Grounds: Add XP'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: StatKey.values.map((key) {
              return ListTile(
                title: Text(key.label),
                subtitle: Text(OperatorCopy.statLabel(key.name)),
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

class _CompoundView extends ConsumerWidget {
  final List<Stat> stats;
  final DateTime installDate;

  const _CompoundView({required this.stats, required this.installDate});

  void _showBuildingCommandSheet(
    BuildContext context, {
    required Stat stat,
    required int tier,
    required int ghostLevel,
    required bool hasPending,
    required bool isBehindPace,
  }) {
    final color = BuildingConfig.colorForStat(stat.statKey);
    final nextLevelXp = XpConfig.xpForLevel(stat.level + 1);
    final xpRemaining = math.max(0, nextLevelXp - stat.currentXp);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: OperatorGradients.panel,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: color.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withValues(alpha: 0.45)),
                      ),
                      child: Icon(Icons.home_work_outlined, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(OperatorCopy.shortStatLabel(stat.statKey).toUpperCase(), style: OperatorTextStyles.overline),
                          const SizedBox(height: 4),
                          Text(OperatorCopy.statLabel(stat.statKey), style: OperatorTextStyles.title),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(label: 'Level ${stat.level}', color: color),
                    _StatusPill(label: 'Tier $tier • ${OperatorCopy.tierName(tier)}', color: OperatorPalette.parchmentGold),
                    if (hasPending) const _StatusPill(label: 'Mission waiting', color: OperatorPalette.warningAmber),
                    if (isBehindPace) const _StatusPill(label: 'Behind blueprint', color: OperatorPalette.hologramBlue),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${stat.currentXp} XP earned • $xpRemaining XP to next level',
                  style: OperatorTextStyles.body,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _levelProgress(stat),
                    minHeight: 8,
                    backgroundColor: OperatorPalette.borderDim,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isBehindPace
                      ? 'The ghost blueprint is ahead at Level $ghostLevel. One focused mission will help this building catch up.'
                      : 'This building is holding formation. Keep feeding it meaningful missions.',
                  style: OperatorTextStyles.body,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatDetailScreen(statKey: stat.statKey),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Building Command'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _levelProgress(Stat stat) {
    if (stat.level == 1) {
      return (stat.currentXp / XpConfig.xpForLevel(2)).clamp(0.0, 1.0).toDouble();
    }
    final currentLevelBase = XpConfig.xpForLevel(stat.level);
    final nextLevelBase = XpConfig.xpForLevel(stat.level + 1);
    final xpInLevel = stat.currentXp - currentLevelBase;
    final xpNeeded = nextLevelBase - currentLevelBase;
    if (xpNeeded <= 0) return 0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;
    var pendingMissionCount = 0;
    for (final stat in stats) {
      final pending = ref.watch(questsByDomainStreamProvider(stat.statKey));
      pendingMissionCount += pending.asData?.value.length ?? 0;
    }
    final compoundLevel = stats.fold<int>(0, (sum, stat) => sum + stat.level);
    final totalXp = stats.fold<int>(0, (sum, stat) => sum + stat.currentXp);

    return Stack(
      children: [
        InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.3,
          maxScale: 3.0,
          child: SizedBox(
            width: 1500,
            height: 1500,
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _CompoundTerrainPainter())),
                ...BuildingConfig.buildingPositions.entries.map((entry) {
                  return Positioned(
                    left: entry.value.dx + 58,
                    top: entry.value.dy + 58,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: OperatorPalette.parchmentGold.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: OperatorPalette.parchmentGold.withValues(alpha: 0.2),
                            blurRadius: 18,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // Real buildings
                ...stats.map((stat) {
                  final position = BuildingConfig.buildingPositions[stat.statKey]!;
                  final tier = XpConfig.tierForLevel(stat.level);
                  final ghostLevel = PaceConfig.paceLevelForStat(stat.statKey, daysSinceInstall);
                  final pendingAsync = ref.watch(
                    questsByDomainStreamProvider(stat.statKey),
                  );
                  final hasPending = pendingAsync.when(
                    data: (quests) => quests.isNotEmpty,
                    loading: () => false,
                    error: (_, __) => false,
                  );
                  final isBehindPace = stat.level < ghostLevel;

                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: BuildingWidget(
                      key: ValueKey('${stat.statKey}_real'),
                      statKey: stat.statKey,
                      level: stat.level,
                      currentXp: stat.currentXp,
                      tier: tier,
                      hasPendingQuests: hasPending,
                      isBehindPace: isBehindPace,
                      onTap: () => _showBuildingCommandSheet(
                        context,
                        stat: stat,
                        tier: tier,
                        ghostLevel: ghostLevel,
                        hasPending: hasPending,
                        isBehindPace: isBehindPace,
                      ),
                    ),
                  );
                }),

                // Ghost buildings
                ...stats.map((stat) {
                  final position = BuildingConfig.buildingPositions[stat.statKey]!;
                  final ghostTier = PaceConfig.paceTierForStat(stat.statKey, daysSinceInstall);
                  final ghostLevel = PaceConfig.paceLevelForStat(stat.statKey, daysSinceInstall);

                  return Positioned(
                    left: position.dx + BuildingConfig.ghostOffsetX,
                    top: position.dy + BuildingConfig.ghostOffsetY,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.35,
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
                  );
                }),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OperatorWorldHud(
                compoundLevel: compoundLevel,
                totalXp: totalXp,
                activeMissions: pendingMissionCount,
                campaignLabel: 'Day $daysSinceInstall',
                councilLabel: 'Blueprints',
                compact: true,
              ),
              const SizedBox(height: 10),
              _CompoundLegend(daysSinceInstall: daysSinceInstall),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CompoundLegend extends StatelessWidget {
  final int daysSinceInstall;

  const _CompoundLegend({required this.daysSinceInstall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OperatorPalette.panelDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OperatorPalette.borderDim),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OperatorPalette.hologramBlue.withValues(alpha: 0.12),
              border: Border.all(color: OperatorPalette.hologramBlue.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.auto_awesome, color: OperatorPalette.hologramBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LIVING COMPOUND', style: OperatorTextStyles.overline),
                const SizedBox(height: 3),
                Text(
                  'Day $daysSinceInstall • Blue ghosts show your pace blueprint.',
                  style: OperatorTextStyles.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompoundTerrainPainter extends CustomPainter {
  const _CompoundTerrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF102415),
          Color(0xFF17351F),
          Color(0xFF0B1714),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          OperatorPalette.voidBlack.withValues(alpha: 0.58),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);

    final pathPaint = Paint()
      ..color = const Color(0xFF7A6338).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    final pathHighlight = Paint()
      ..color = OperatorPalette.parchmentGold.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final points = BuildingConfig.buildingPositions.values
        .map((o) => Offset(o.dx + 60, o.dy + 60))
        .toList();
    final center = Offset(size.width / 2, size.height / 2);
    for (final point in points) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo((center.dx + point.dx) / 2, center.dy, point.dx, point.dy);
      canvas.drawPath(path, pathPaint);
      canvas.drawPath(path, pathHighlight);
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 120) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 120) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
