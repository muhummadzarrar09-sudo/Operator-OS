class AiRuntimeReport {
  final String mode;
  final String modelName;
  final String status;
  final String detail;
  final String? detectedModelPath;
  final List<String> searchedPaths;
  final List<String> expectedFileNames;

  const AiRuntimeReport({
    required this.mode,
    required this.modelName,
    required this.status,
    required this.detail,
    this.detectedModelPath,
    this.searchedPaths = const [],
    this.expectedFileNames = const [],
  });

  bool get hasDetectedModel => detectedModelPath != null;
}
