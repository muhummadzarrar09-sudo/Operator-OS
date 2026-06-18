import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_runtime_status.dart';
import 'ai_service.dart';
import 'mock_ai_service.dart';

/// Gemma-ready AI service.
///
/// IMPORTANT: This build keeps the existing dependency lock intact. No native
/// Gemma inference runtime is wired here because that would require dependency,
/// model-format, and device testing decisions outside this sandbox.
///
/// What this service does now:
/// - preserves the existing AiService contract;
/// - searches a local "Model Vault" for expected Gemma model filenames;
/// - reports honest runtime status to the UI;
/// - falls back to MockAiService so the app remains usable.
///
/// Future real integration point:
/// Replace the fallback calls below with a verified Gemma runtime while keeping
/// this class behind the existing AiService interface.
class GemmaAiService implements AiService {
  static const List<String> expectedModelFileNames = [
    'gemma-3n-e4b-it-q4.task',
    'gemma-3n-e4b.task',
    'gemma-3-4b-it-q4.task',
    'gemma-3-e4b.task',
    'operator_gemma.task',
  ];

  final AiService _delegate = MockAiService();
  bool _initialized = false;
  String? _detectedModelPath;
  List<String> _searchedPaths = const [];
  String _lastDetail = 'Model Vault has not been inspected yet.';

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    await _inspectModelVault();
    _initialized = true;
    return _delegate.initialize();
  }

  Future<AiRuntimeReport> runtimeReport() async {
    await initialize();
    final hasModel = _detectedModelPath != null;
    return AiRuntimeReport(
      mode: hasModel ? 'Gemma-ready fallback' : 'Fallback',
      modelName: hasModel ? 'Gemma candidate detected' : 'MockAiService',
      status: hasModel ? 'Model file found; native runtime pending.' : 'No local Gemma model detected.',
      detail: hasModel
          ? 'A model candidate was found, but this dependency-locked build still uses fallback generation until a verified Gemma runtime is approved and wired.'
          : _lastDetail,
      detectedModelPath: _detectedModelPath,
      searchedPaths: _searchedPaths,
      expectedFileNames: expectedModelFileNames,
    );
  }

  Future<void> _inspectModelVault() async {
    final searched = <String>[];
    try {
      final docs = await getApplicationDocumentsDirectory();
      final candidateDirs = [
        Directory('${docs.path}/operator_os_models'),
        Directory('${docs.path}/models'),
        docs,
      ];

      for (final dir in candidateDirs) {
        for (final fileName in expectedModelFileNames) {
          final path = '${dir.path}/$fileName';
          searched.add(path);
          if (await File(path).exists()) {
            _detectedModelPath = path;
            _searchedPaths = searched;
            _lastDetail = 'Detected model candidate at $path.';
            debugPrint('Operator OS Gemma model candidate detected: $path');
            return;
          }
        }
      }

      _searchedPaths = searched;
      _lastDetail = 'Place a supported Gemma model file in the app documents Model Vault when native runtime support is approved.';
    } catch (e) {
      _searchedPaths = searched;
      _lastDetail = 'Could not inspect Model Vault in this environment: $e';
      debugPrint('GemmaAiService Model Vault inspection failed: $e');
    }
  }

  @override
  Future<List<double>?> generateEmbedding(String text) =>
      _delegate.generateEmbedding(text);

  @override
  Future<String?> generateText(String prompt, {int maxTokens = 512}) =>
      _delegate.generateText(prompt, maxTokens: maxTokens);

  @override
  Future<void> dispose() => _delegate.dispose();
}
