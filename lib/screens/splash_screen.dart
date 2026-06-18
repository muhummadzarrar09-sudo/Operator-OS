import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';

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
  int _lineIndex = 0;
  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();
    _lineTimer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      if (!mounted) return;
      setState(() {
        _lineIndex = (_lineIndex + 1) % OperatorCopy.loadingLines.length;
      });
    });
    _init();
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    super.dispose();
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

    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.25 + value * 0.12),
                    radius: 1.1,
                    colors: const [
                      Color(0x332A5A7A),
                      OperatorPalette.nightNavy,
                      OperatorPalette.voidBlack,
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _GatePainter(progress: value)),
              ),
              Center(
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(
                    scale: 0.92 + value * 0.08,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 104,
                          width: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OperatorPalette.panelRaised.withValues(alpha: 0.82),
                            border: Border.all(
                              color: OperatorPalette.parchmentGold.withValues(alpha: 0.65),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: OperatorPalette.torchOrange.withValues(alpha: 0.32),
                                blurRadius: 34,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/compound/operator_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield_moon_outlined,
                                color: OperatorPalette.parchmentGold,
                                size: 52,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'OPERATOR OS',
                          style: TextStyle(
                            color: OperatorPalette.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'THE COMPOUND AWAKENS',
                          style: OperatorTextStyles.overline,
                        ),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            OperatorCopy.loadingLines[_lineIndex],
                            key: ValueKey(_lineIndex),
                            style: OperatorTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 180,
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 3,
                            backgroundColor: OperatorPalette.borderDim,
                            valueColor: const AlwaysStoppedAnimation(
                              OperatorPalette.parchmentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GatePainter extends CustomPainter {
  final double progress;

  _GatePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gatePaint = Paint()
      ..color = const Color(0xAA050812)
      ..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..color = OperatorPalette.torchOrange.withValues(alpha: 0.16 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    final opening = size.width * 0.12 * progress;
    final centerX = size.width / 2;

    canvas.drawCircle(Offset(centerX, size.height * 0.46), 120 + progress * 80, glowPaint);
    canvas.drawRect(Rect.fromLTRB(0, 0, centerX - opening, size.height), gatePaint);
    canvas.drawRect(Rect.fromLTRB(centerX + opening, 0, size.width, size.height), gatePaint);

    final seamPaint = Paint()
      ..color = OperatorPalette.parchmentGold.withValues(alpha: 0.18)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(centerX - opening, 0),
      Offset(centerX - opening, size.height),
      seamPaint,
    );
    canvas.drawLine(
      Offset(centerX + opening, 0),
      Offset(centerX + opening, size.height),
      seamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GatePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
