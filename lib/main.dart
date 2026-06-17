import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/sync_service.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

/// True once Supabase.initialize() has completed successfully. Deep-link auth
/// handling must wait for this so a cold-start magic-link URI is only handed to
/// the client after it is ready.
bool supabaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase must be initialized before runApp because the rest of the app
  // calls Supabase.instance.client. But it must never hang the splash screen,
  // so we bound it with a 5s timeout and swallow any error/timeout.
  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      publishableKey: SupabaseConstants.publishableKey,
    ).timeout(const Duration(seconds: 5));
    supabaseInitialized = true;
  } catch (e) {
    debugPrint('Supabase.initialize failed or timed out: $e');
  }

  // Fire-and-forget notification setup so it can never block startup
  // (e.g. permission prompts on first boot).
  try {
    NotificationService().initialize().catchError((Object e) {
      debugPrint('NotificationService.initialize failed: $e');
    });
  } catch (e) {
    debugPrint('NotificationService.initialize threw synchronously: $e');
  }

  runApp(const ProviderScope(child: OperatorOSApp()));
}

class OperatorOSApp extends ConsumerStatefulWidget {
  const OperatorOSApp({super.key});

  @override
  ConsumerState<OperatorOSApp> createState() => _OperatorOSAppState();
}

class _OperatorOSAppState extends ConsumerState<OperatorOSApp>
    with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    _sync();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Listens for the Supabase magic-link redirect
  /// (io.supabase.operatoros://login-callback/) and completes the auth flow.
  Future<void> _initDeepLinks() async {
    // Subscribe first so a link that arrives while we're starting up isn't
    // missed. These fire when a link opens the app while it's already running.
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleAuthDeepLink,
      onError: (Object e) => debugPrint('uriLinkStream error: $e'),
    );

    // Cold-start link: the URI that launched the app. Only process it once
    // Supabase.initialize() has fully completed, otherwise the client isn't
    // ready to exchange the code for a session.
    if (!supabaseInitialized) return;
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleAuthDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('getInitialLink failed: $e');
    }
  }

  Future<void> _handleAuthDeepLink(Uri uri) async {
    // Only callback URIs from Supabase carry an auth session.
    if (uri.host != 'login-callback' && uri.host != 'callback') return;
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      // getSessionFromUrl fires onAuthStateChange(signedIn) internally, but
      // invalidate authProvider too so any current listener re-reads the new
      // session immediately and the UI leaves the sign-in screen.
      ref.invalidate(authProvider);
      _sync();
    } catch (e) {
      debugPrint('getSessionFromUrl failed: $e');
    }
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
