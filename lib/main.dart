import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/sync_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.url,
    publishableKey: SupabaseConstants.publishableKey,
  );
  await NotificationService().initialize();
  runApp(const ProviderScope(child: OperatorOSApp()));
}

class OperatorOSApp extends ConsumerStatefulWidget {
  const OperatorOSApp({super.key});

  @override
  ConsumerState<OperatorOSApp> createState() => _OperatorOSAppState();
}

class _OperatorOSAppState extends ConsumerState<OperatorOSApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.paused) {
      _sync();
    }
  }

  void _sync() {
    try {
      final auth = Supabase.instance.client.auth.currentUser;
      if (auth != null) {
        ref.read(syncServiceProvider).performSync();
      }
    } catch (_) {
      // Supabase not initialized yet (e.g. widget tests) - skip sync.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Operator OS',
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
