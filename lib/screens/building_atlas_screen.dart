import 'package:flutter/material.dart';
import 'package:operator_os/core/building_config.dart';
import 'package:operator_os/core/constants.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/widgets/operator_card.dart';

class BuildingAtlasScreen extends StatelessWidget {
  const BuildingAtlasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(title: const Text('Building Atlas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OperatorCard(
            label: 'COMPOUND ATLAS',
            title: 'Building art readiness.',
            body: 'Review the current building sprites across all tiers. Missing assets fall back to a blueprint tile until the final 32-building art set is complete.',
            icon: Icons.auto_awesome_mosaic_outlined,
            accentColor: OperatorPalette.parchmentGold,
          ),
          const SizedBox(height: 16),
          ...StatKey.values.map((key) => _BuildingFamilyCard(statKey: key.name)),
        ],
      ),
    );
  }
}

class _BuildingFamilyCard extends StatelessWidget {
  final String statKey;

  const _BuildingFamilyCard({required this.statKey});

  @override
  Widget build(BuildContext context) {
    final color = BuildingConfig.colorForStat(statKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OperatorCard(
        accentColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statKey.toUpperCase(), style: OperatorTextStyles.overline),
            const SizedBox(height: 6),
            Text(OperatorCopy.statLabel(statKey), style: OperatorTextStyles.title),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final tier = index + 1;
                return _TierTile(statKey: statKey, tier: tier, color: color);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final String statKey;
  final int tier;
  final Color color;

  const _TierTile({required this.statKey, required this.tier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: OperatorPalette.voidBlack.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              'assets/compound/${statKey}_t$tier.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _MissingBlueprint(color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'T$tier',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingBlueprint extends StatelessWidget {
  final Color color;

  const _MissingBlueprint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OperatorPalette.hologramBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OperatorPalette.hologramBlue.withValues(alpha: 0.32)),
      ),
      child: Center(
        child: Icon(
          Icons.domain_add_outlined,
          color: color.withValues(alpha: 0.75),
          size: 24,
        ),
      ),
    );
  }
}
