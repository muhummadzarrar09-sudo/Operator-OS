import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/screens/sign_in_screen.dart';

/// Signs out and force-clears the navigation stack so the user cannot remain
/// inside authenticated screens after local/Supabase auth is cleared.
Future<void> signOutAndReturnToLogin(BuildContext context, WidgetRef ref) async {
  await ref.read(authProvider.notifier).signOut();
  if (!context.mounted) return;

  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    (_) => false,
  );
}
