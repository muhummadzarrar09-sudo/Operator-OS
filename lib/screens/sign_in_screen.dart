import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/widgets/operator_card.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  bool _redirected = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (_redirected || !mounted) return;
    _redirected = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ref.read(authProvider.notifier).signInWithMagicLink(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate link sent — check your email.')),
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

  @override
  Widget build(BuildContext context) {
    // When the magic-link deep link establishes a session, the auth stream
    // flips this provider to true and we leave the sign-in screen for good.
    ref.listen(isAuthenticatedProvider, (previous, next) {
      if (next) _goHome();
    });
    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 132,
                  width: 132,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OperatorPalette.panelRaised.withValues(alpha: 0.86),
                    border: Border.all(
                      color: OperatorPalette.parchmentGold.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: OperatorPalette.torchOrange.withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/compound/operator_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_moon_outlined,
                        color: OperatorPalette.parchmentGold,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'OPERATOR OS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: OperatorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the Compound. Build the Operator.',
                  textAlign: TextAlign.center,
                  style: OperatorTextStyles.body,
                ),
                const SizedBox(height: 30),
                OperatorCard(
                  label: 'GATE ACCESS',
                  title: 'Identify yourself, Operator.',
                  body: 'Sign in to restore your missions, buildings, memories, and Council records.',
                  icon: Icons.lock_open_outlined,
                  accentColor: OperatorPalette.parchmentGold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_open_outlined, color: OperatorPalette.parchmentGold),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GATE ACCESS', style: OperatorTextStyles.overline),
                                SizedBox(height: 4),
                                Text('Identify yourself, Operator.', style: OperatorTextStyles.title),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                        icon: const Icon(Icons.login),
                        label: const Text('Enter with Google'),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: OperatorTextStyles.muted),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'operator@email.com',
                          filled: true,
                          fillColor: OperatorPalette.panelDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isSending ? null : _sendMagicLink,
                        child: _isSending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send Gate Link'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
