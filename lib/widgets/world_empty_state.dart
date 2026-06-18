import 'package:flutter/material.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/widgets/operator_card.dart';

class WorldEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  const WorldEmptyState({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: OperatorCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OperatorPalette.parchmentGold.withValues(alpha: 0.12),
                  border: Border.all(
                    color: OperatorPalette.parchmentGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, size: 36, color: OperatorPalette.parchmentGold),
              ),
              const SizedBox(height: 18),
              Text(label, style: OperatorTextStyles.overline, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(title, style: OperatorTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(body, style: OperatorTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.explore),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
