import 'package:flutter/material.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/widgets/operator_card.dart';

Future<void> showMissionCompleteCeremony({
  required BuildContext context,
  required String statKey,
  required int xp,
  String title = 'Mission complete.',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(22),
        child: OperatorCard(
          accentColor: OperatorPalette.parchmentGold,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 78,
                  width: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OperatorPalette.parchmentGold.withValues(alpha: 0.14),
                    border: Border.all(color: OperatorPalette.parchmentGold.withValues(alpha: 0.55)),
                    boxShadow: [
                      BoxShadow(
                        color: OperatorPalette.torchOrange.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.military_tech_outlined,
                    color: OperatorPalette.parchmentGold,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('MISSION COMPLETE', style: OperatorTextStyles.overline, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(title, style: OperatorTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                '+$xp XP to ${OperatorCopy.shortStatLabel(statKey)}',
                style: const TextStyle(
                  color: OperatorPalette.parchmentGold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                OperatorCopy.buildingLine(statKey),
                style: OperatorTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
