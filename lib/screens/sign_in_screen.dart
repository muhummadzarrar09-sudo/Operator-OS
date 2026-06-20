import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/screens/home_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  late final AnimationController _ambientController;
  bool _isSending = false;
  bool _isLaunchingLocal = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continueLocal() async {
    setState(() => _isLaunchingLocal = true);
    try {
      await ref.read(authProvider.notifier).signInLocal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Local mode failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunchingLocal = false);
    }
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ref.read(authProvider.notifier).signInWithMagicLink(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Magic link sent — check your email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == null && next != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
    });

    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Stack(
            children: [
              const Positioned.fill(child: _LoginBackground()),
              Positioned.fill(child: CustomPaint(painter: _LoginAmbientPainter(_ambientController.value))),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LoginHero(),
                          const SizedBox(height: 26),
                          _LoginPanel(
                            emailController: _emailController,
                            isSending: _isSending,
                            isLaunchingLocal: _isLaunchingLocal,
                            onLocal: _continueLocal,
                            onGoogle: _signInWithGoogle,
                            onMagicLink: _sendMagicLink,
                          ),
                        ],
                      ),
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

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OperatorPalette.voidBlack,
            OperatorPalette.nightNavy,
            Color(0xFF0A1410),
          ],
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        children: [
          Container(
            height: 112,
            width: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: OperatorPalette.parchmentGold.withValues(alpha: 0.6), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: OperatorPalette.torchOrange.withValues(alpha: 0.25),
                  blurRadius: 38,
                  spreadRadius: 5,
                ),
              ],
              gradient: const RadialGradient(
                colors: [
                  OperatorPalette.torchOrange,
                  OperatorPalette.parchmentGold,
                  Color(0xFF2A1E0F),
                ],
              ),
            ),
            child: const Icon(Icons.castle_outlined, size: 58, color: OperatorPalette.voidBlack),
          ),
          const SizedBox(height: 20),
          const Text(
            'OPERATOR OS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OperatorPalette.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A simple command center for missions, XP, and your Compound.',
            textAlign: TextAlign.center,
            style: OperatorTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final TextEditingController emailController;
  final bool isSending;
  final bool isLaunchingLocal;
  final VoidCallback onLocal;
  final VoidCallback onGoogle;
  final VoidCallback onMagicLink;

  const _LoginPanel({
    required this.emailController,
    required this.isSending,
    required this.isLaunchingLocal,
    required this.onLocal,
    required this.onGoogle,
    required this.onMagicLink,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1050),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 32 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: OperatorPalette.panelDark.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: OperatorPalette.borderDim),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: isLaunchingLocal ? null : onLocal,
              icon: isLaunchingLocal
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flash_on),
              label: const Text('Enter Personal Mode'),
            ),
            const SizedBox(height: 10),
            Text(
              'Recommended while Supabase is not configured. Saves to your local device database.',
              textAlign: TextAlign.center,
              style: OperatorTextStyles.muted.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: Divider(color: OperatorPalette.borderDim)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR MAGIC LINK', style: OperatorTextStyles.muted),
                ),
                Expanded(child: Divider(color: OperatorPalette.borderDim)),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isSending ? null : onMagicLink,
              child: isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Magic Link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginAmbientPainter extends CustomPainter {
  final double progress;

  const _LoginAmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          OperatorPalette.hologramBlue.withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.78, size.height * 0.22),
        radius: size.width * 0.55,
      ));
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.22), size.width * 0.55, orbPaint);

    final particlePaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int i = 0; i < 14; i++) {
      final phase = (progress + i * 0.09) % 1.0;
      final x = size.width * (((i * 37) % 100) / 100) + math.sin(progress * math.pi * 2 + i) * 18;
      final y = size.height * (1.05 - phase * 1.18);
      final pulse = math.sin(progress * math.pi * 2 + i).abs();
      particlePaint.color = (i.isEven ? OperatorPalette.parchmentGold : OperatorPalette.torchOrange)
          .withValues(alpha: 0.10 + pulse * 0.16);
      canvas.drawCircle(Offset(x, y), 2.0 + pulse * 3.4, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
