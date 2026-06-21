import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _introDuration = Duration(milliseconds: 4800);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _introDuration)..forward();
    _init();
  }

  Future<void> _init() async {
    // Restore offline/local mode, but never let it block the splash from
    // advancing. A throw or a stall in SharedPreferences here must not freeze
    // the loading screen at 100% — bound it with a timeout and swallow errors
    // so navigation always happens once the intro animation finishes.
    final restoreLocalMode = ref
        .read(authProvider.notifier)
        .restoreLocalMode()
        .timeout(const Duration(seconds: 3))
        .catchError((Object e) {
      debugPrint('Splash: restoreLocalMode failed/timed out (ignored): $e');
    });

    // Run the restore concurrently with the intro animation, then advance.
    await Future.wait<void>([
      Future<void>.delayed(_introDuration),
      restoreLocalMode,
    ]);

    if (!mounted) return;

    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      // Supabase not initialized yet (e.g. widget tests) - treat as signed out.
      session = null;
    }

    final localUserId = ref.read(localUserIdProvider);
    final isAuthenticated = session != null || localUserId != null;
    final hasSeenWalkthrough = isAuthenticated
        ? await hasCompletedOperatorOnboarding()
        : false;
    final destination = isAuthenticated
        ? hasSeenWalkthrough
            ? const HomeScreen()
            : const OnboardingScreen(destination: HomeScreen())
        : const SignInScreen();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: destination,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final lineIndex = (_controller.value * OperatorCopy.loadingLines.length)
              .floor()
              .clamp(0, OperatorCopy.loadingLines.length - 1)
              .toInt();
          return Stack(
            children: [
              const Positioned.fill(child: _SplashBackground()),
              Positioned.fill(child: CustomPaint(painter: _SplashParticlesPainter(t))),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Transform.scale(
                    scale: 0.92 + (0.08 * t),
                    child: Opacity(
                      opacity: (t * 1.35).clamp(0.0, 1.0).toDouble(),
                      child: const _SplashMark(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                right: 32,
                bottom: 52,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(OperatorPalette.parchmentGold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      OperatorCopy.loadingLines[lineIndex],
                      textAlign: TextAlign.center,
                      style: OperatorTextStyles.muted,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.25, -0.35),
          radius: 1.3,
          colors: [
            Color(0x332A5CFF),
            OperatorPalette.nightNavy,
            OperatorPalette.voidBlack,
          ],
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [OperatorPalette.parchmentGold, OperatorPalette.torchOrange],
            ),
            boxShadow: [
              BoxShadow(
                color: OperatorPalette.torchOrange.withValues(alpha: 0.35),
                blurRadius: 42,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.shield_moon_outlined, size: 58, color: OperatorPalette.voidBlack),
        ),
        const SizedBox(height: 24),
        const Text(
          'OPERATOR OS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: OperatorPalette.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your base. Your missions. Your momentum.',
          textAlign: TextAlign.center,
          style: OperatorTextStyles.body,
        ),
      ],
    );
  }
}

class _SplashParticlesPainter extends CustomPainter {
  final double progress;

  const _SplashParticlesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int i = 0; i < 18; i++) {
      final phase = (progress + i * 0.071) % 1.0;
      final x = ((i * 97) % 100) / 100 * size.width;
      final y = size.height * (1.05 - phase * 1.16);
      final drift = math.sin((progress * math.pi * 2) + i) * 28;
      final pulse = 0.45 + 0.55 * math.sin(progress * math.pi * 2 + i).abs();
      paint.color = (i.isEven ? OperatorPalette.parchmentGold : OperatorPalette.hologramBlue)
          .withValues(alpha: 0.10 + pulse * 0.18);
      canvas.drawCircle(Offset(x + drift, y), 2.4 + pulse * 3.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
