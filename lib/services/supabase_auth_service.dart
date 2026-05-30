import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class SupabaseAuthService {
  static bool _initialized = false;

  static bool get isConfigured =>
      SUPABASE_URL.isNotEmpty && SUPABASE_ANON_KEY.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        'Supabase auth is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.',
      );
      return;
    }

    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
    _initialized = true;
  }

  SupabaseClient get _client {
    if (!_initialized) {
      throw StateError('Supabase auth is not initialized.');
    }
    return Supabase.instance.client;
  }

  User? get currentUser => _initialized ? _client.auth.currentUser : null;

  Session? get currentSession =>
      _initialized ? _client.auth.currentSession : null;

  String? get currentUserId => currentUser?.id;

  String? get currentAccessToken => currentSession?.accessToken;

  Stream<AuthState> get authStateChanges {
    if (!_initialized) {
      return const Stream<AuthState>.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      },
    );
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) {
    return _client.auth.updateUser(
      UserAttributes(
        data: {
          if (displayName != null) 'display_name': displayName,
          if (photoURL != null) 'photo_url': photoURL,
        },
      ),
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> deleteUser() {
    throw UnsupportedError(
      'Account deletion must be performed by the backend with Supabase admin privileges.',
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}
