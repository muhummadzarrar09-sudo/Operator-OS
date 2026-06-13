import 'dart:convert';

class SubStatsConfig {
  static const Map<String, List<String>> subStats = {
    'forge': ['algorithms', 'ml_nn', 'architecture', 'shipping'],
    'academy': ['math', 'physics', 'cs', 'mock_tests'],
    'leverage': ['sales', 'negotiation', 'strategy'],
    'presence': ['warmth', 'power', 'presence'],
    'craft': ['writing', 'design', 'ideation'],
    'vitality': ['strength', 'conditioning', 'golf'],
    'capital': ['saving', 'investing', 'literacy'],
    'clarity': ['reasoning', 'reflection', 'models'],
  };

  static Map<String, int> parseValues(String json) {
    if (json.isEmpty || json == '{}') return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }
}
