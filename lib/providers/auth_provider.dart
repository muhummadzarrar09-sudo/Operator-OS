import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

const String localOperatorUserId = 'local-operator';
const String _localModePrefsKey = 'operator_os_local_mode_enabled';

/// Manual state used for the personal/offline mode. Supabase is still supported,
/// but this lets the app boot and keep local Drift data even when Supabase auth
/// is not configured or you just want the app for yourself.
@riverpod
class LocalUserId extends _$LocalUserId {
  @override
  String? build() => null;

  void setUserId(String? userId) {
    state = userId;
  }
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<AuthState> build() {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  String? get currentUserId {
    return Supabase.instance.client.auth.currentUser?.id ?? ref.read(localUserIdProvider);
  }

  Future<void> restoreLocalMode() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_localModePrefsKey) ?? false;
    ref.read(localUserIdProvider.notifier).setUserId(
          enabled ? localOperatorUserId : null,
        );
  }

  Future<void> signInLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localModePrefsKey, true);
    ref.read(localUserIdProvider.notifier).setUserId(localOperatorUserId);
  }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localModePrefsKey);
      ref.read(localUserIdProvider.notifier).setUserId(null);
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error (ignored): $e');
    }
  }
}

@riverpod
String? currentUserId(Ref ref) {
  // Re-evaluate whenever either Supabase auth or local/offline auth changes.
  ref.watch(authProvider);
  final localUserId = ref.watch(localUserIdProvider);
  return Supabase.instance.client.auth.currentUser?.id ?? localUserId;
}
