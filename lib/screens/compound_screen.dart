import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/data/database.dart';
import 'package:operator_os/data/repositories/stats_repository.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/providers/install_date_provider.dart';
import 'package:operator_os/providers/quests_provider.dart';
import 'package:operator_os/providers/stats_provider.dart';
import 'package:operator_os/providers/user_initializer.dart';
import 'package:operator_os/screens/stat_detail_screen.dart';
import 'package:operator_os/widgets/building_widget.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDebugXpDialog(context, ref),
        child: const Icon(Icons.bug_report),
      ),
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

class _CompoundView extends ConsumerWidget {
  final List<Stat> stats;
  final DateTime installDate;

  const _CompoundView({required this.stats, required this.installDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.3,
      maxScale: 3.0,
      child: Container(
        width: 1500,
        height: 1500,
        color: const Color(0xFF1B3A1B), // dark green terrain placeholder
        child: Stack(
          children: [
            // Real buildings
            ...stats.map((stat) {
              final position = BuildingConfig.buildingPositions[stat.statKey]!;
              final tier = XpConfig.tierForLevel(stat.level);
              final pendingAsync = ref.watch(
                questsByDomainStreamProvider(stat.statKey),
              );
              final hasPending = pendingAsync.when(
                data: (quests) => quests.isNotEmpty,
                loading: () => false,
                error: (_, __) => false,
              );

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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StatDetailScreen(statKey: stat.statKey),
                    ),
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
    );
  }
}
