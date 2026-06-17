import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<AuthState> build() {
    // Returning the broadcast stream makes this StreamNotifier emit a fresh
    // AsyncData(AuthState) on every auth event (signedIn, signedOut, token
    // refreshed, ...). Each emission rebuilds every widget that watches
    // authProvider, which is how the UI reacts when the magic-link deep link
    // establishes a session.
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
        emailRedirectTo: 'io.supabase.operatoros://login-callback/',
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

/// True whenever there is an active Supabase session.
///
/// Re-evaluated on every auth event via [authProvider], and falls back to the
/// client's current session so screens see the right value even before the
/// auth stream has emitted its first event (e.g. on cold start).
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authProvider);
  final sessionFromStream = authState.asData?.value.session;
  if (sessionFromStream != null) return true;
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    // Supabase not initialized yet (e.g. widget tests) - treat as signed out.
    return false;
  }
}
