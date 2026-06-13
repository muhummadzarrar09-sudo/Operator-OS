import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final installDateProvider = FutureProvider<DateTime>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getInt('install_date_ms');
  if (stored != null) {
    return DateTime.fromMillisecondsSinceEpoch(stored);
  }
  final now = DateTime.now();
  await prefs.setInt('install_date_ms', now.millisecondsSinceEpoch);
  return now;
});
