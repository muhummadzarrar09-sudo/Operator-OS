import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;
    // ref.read instead of watch: this is a one-shot initial-load decision.
    // Ongoing auth changes (e.g. a magic-link deep link landing while the
    // splash is still showing) are handled by the ref.listen in build().
    final authed = ref.read(isAuthenticatedProvider);
    _go(authed ? const HomeScreen() : const SignInScreen());
  }

  /// Navigates exactly once; later auth events can't double-push.
  void _go(Widget screen) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If auth completes (e.g. the magic-link deep link) while the splash is
    // still visible, jump straight to home instead of waiting for the timer.
    ref.listen(isAuthenticatedProvider, (previous, next) {
      if (next) _go(const HomeScreen());
    });
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
