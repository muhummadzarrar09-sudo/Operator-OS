import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/services/gemma_ai_service.dart';
import 'package:operator_os/widgets/operator_card.dart';

class ModelVaultScreen extends ConsumerWidget {
  const ModelVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.read(aiServiceProvider);

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(title: const Text('Model Vault')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OperatorCard(
            label: 'GEMMA MODEL VAULT',
            title: 'Local model readiness layer.',
            body: 'This screen is the safe Phase 5 bridge: it can detect prepared Gemma model files without changing dependencies or touching the working app foundation.',
            icon: Icons.memory_outlined,
            accentColor: OperatorPalette.hologramBlue,
          ),
          const SizedBox(height: 16),
          if (ai is GemmaAiService)
            FutureBuilder(
              future: ai.runtimeReport(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final report = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OperatorCard(
                      label: 'RUNTIME STATUS',
                      title: report.status,
                      body: '${report.detail}\n\nMode: ${report.mode}\nModel: ${report.modelName}',
                      icon: report.hasDetectedModel ? Icons.check_circle_outline : Icons.info_outline,
                      accentColor: report.hasDetectedModel
                          ? OperatorPalette.successGreen
                          : OperatorPalette.warningAmber,
                    ),
                    const SizedBox(height: 16),
                    OperatorCard(
                      label: 'EXPECTED MODEL FILES',
                      title: 'Approved names for future runtime wiring.',
                      icon: Icons.list_alt,
                      accentColor: OperatorPalette.parchmentGold,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPECTED MODEL FILES', style: OperatorTextStyles.overline),
                          const SizedBox(height: 8),
                          const Text('Approved names for future runtime wiring.', style: OperatorTextStyles.title),
                          const SizedBox(height: 12),
                          ...report.expectedFileNames.map(
                            (name) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined, size: 16, color: OperatorPalette.textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(name, style: OperatorTextStyles.body)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OperatorCard(
                      label: 'SEARCH PATHS',
                      title: 'Where the app looked this session.',
                      icon: Icons.folder_open,
                      accentColor: OperatorPalette.hologramBlue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SEARCH PATHS', style: OperatorTextStyles.overline),
                          const SizedBox(height: 8),
                          const Text('Where the app looked this session.', style: OperatorTextStyles.title),
                          const SizedBox(height: 12),
                          if (report.searchedPaths.isEmpty)
                            const Text('No paths available in this environment yet.', style: OperatorTextStyles.body)
                          else
                            ...report.searchedPaths.take(12).map(
                                  (path) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(path, style: OperatorTextStyles.muted),
                                  ),
                                ),
                          if (report.searchedPaths.length > 12)
                            Text('+${report.searchedPaths.length - 12} more paths', style: OperatorTextStyles.muted),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          else
            const OperatorCard(
              label: 'RUNTIME STATUS',
              title: 'Non-Gemma AI service active.',
              body: 'The current provider is not GemmaAiService, so the Model Vault cannot inspect runtime readiness.',
              icon: Icons.info_outline,
              accentColor: OperatorPalette.warningAmber,
            ),
        ],
      ),
    );
  }
}
