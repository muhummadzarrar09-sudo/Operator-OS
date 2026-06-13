import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<AuthState> build() {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.operatoros://callback',
      );
    } on AuthException catch (e) {
      throw Exception('Google sign-in failed: ${e.message}');
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) throw Exception('Email is empty');
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: trimmed,
        shouldCreateUser: true,
        emailRedirectTo: 'io.supabase.operatoros://callback',
      );
    } on AuthException catch (e) {
      throw Exception('Magic link failed: ${e.message}');
    } catch (e) {
      throw Exception('Magic link failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error (ignored): $e');
    }
  }
}

@riverpod
String? currentUserId(Ref ref) {
  // Re-evaluate whenever auth state changes.
  ref.watch(authProvider);
  return Supabase.instance.client.auth.currentUser?.id;
}
