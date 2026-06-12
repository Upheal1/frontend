import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

class AuthModel extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  Map<String, int> _failedAttempts = {};
  Map<String, UserProfile> _userProfiles = {};
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get errorMessage => _errorMessage;

  AuthModel() {
    _tryRestoreSession();
  }

  /// Returns [Supabase.instance.client] if already initialized, else null.
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Ensures Supabase is initialized (lazily from [config.dart] if needed).
  /// Returns the client on success, or null if configuration is missing.
  Future<SupabaseClient?> _ensureClient() async {
    final existing = _client;
    if (existing != null) return existing;
    try {
      await Supabase.initialize(
        url: SUPABASE_URL,
        anonKey: SUPABASE_ANON_KEY,
        debug: kDebugMode,
      );
      if (kDebugMode) debugPrint('[Auth] Supabase initialized from config.dart');
      return Supabase.instance.client;
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] Failed to init Supabase: $e');
      return null;
    }
  }

  void _tryRestoreSession() {
    final client = _client;
    if (client == null) return;

    final existingSession = client.auth.currentSession;
    if (existingSession != null) {
      _isAuthenticated = true;
      _userEmail = existingSession.user.email;
      _userName = existingSession.user.userMetadata?['display_name'] as String? ??
          existingSession.user.userMetadata?['name'] as String?;
    }

    client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _isAuthenticated = true;
        _userEmail = session.user.email;
        _userName = session.user.userMetadata?['display_name'] as String? ??
            session.user.userMetadata?['name'] as String?;
      } else {
        _isAuthenticated = false;
        _userEmail = null;
        _userName = null;
      }
      notifyListeners();
    });
  }

  String evaluatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 1) return "Weak";
    if (score == 2) return "Medium";
    return "Strong";
  }

  Future<bool> signUp(String email, String password, String name) async {
    final client = await _ensureClient();
    if (client == null) {
      _errorMessage = 'Auth service not configured';
      notifyListeners();
      return false;
    }
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name, 'name': name},
      );
      if (res.user != null) {
        _userEmail = email;
        _userName = name;
        _errorMessage = null;
        if (res.session != null) {
          _isAuthenticated = true;
        }
        notifyListeners();
        return true;
      }
      _errorMessage = 'Account creation failed. If you already signed up, check your email for a confirmation link, or disable email confirmation in Supabase.';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('Signup error: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Signup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool?> login(String email, String password) async {
    final client = await _ensureClient();
    if (client == null) {
      _errorMessage = 'Auth service not configured';
      notifyListeners();
      return false;
    }
    try {
      final storedLock = await _storage.read(key: 'lock_$email');
      if (storedLock != null) {
        final lockDate = DateTime.tryParse(storedLock);
        if (lockDate != null && lockDate.isAfter(DateTime.now())) {
          _errorMessage = 'Account is temporarily locked. Try again later.';
          notifyListeners();
          return false;
        } else {
          await _storage.delete(key: 'lock_$email');
        }
      }

      await client.auth.signInWithPassword(email: email, password: password);

      _failedAttempts[email] = 0;
      await _storage.delete(key: 'lock_$email');
      _isAuthenticated = true;
      _userEmail = email;
      _userName = client.auth.currentUser?.userMetadata?['display_name'] as String? ??
          client.auth.currentUser?.userMetadata?['name'] as String?;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('Login error: ${e.message}');
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if ((_failedAttempts[email] ?? 0) >= 5) {
        final lockUntil =
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
        await _storage.write(key: 'lock_$email', value: lockUntil);
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if ((_failedAttempts[email] ?? 0) >= 5) {
        final lockUntil =
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
        await _storage.write(key: 'lock_$email', value: lockUntil);
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    final client = await _ensureClient();
    if (client == null) {
      _errorMessage = 'Auth service not configured';
      notifyListeners();
      return false;
    }
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: googleWebClientId,
      );
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        _errorMessage = 'Failed to get Google authentication token';
        notifyListeners();
        return false;
      }
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );
      _isAuthenticated = true;
      _userEmail = client.auth.currentUser?.email;
      _userName = client.auth.currentUser?.userMetadata?['display_name'] as String? ??
          client.auth.currentUser?.userMetadata?['name'] as String? ??
          googleUser.displayName;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('Google sign-in error: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Google sign-in error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      if (kDebugMode) debugPrint('Logout error: $e');
    }
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> toggleBiometric(String email, bool enabled) async {
    final profile = _userProfiles[email];
    if (profile == null) return;
    profile.isBiometricEnabled = enabled;
    profile.activities.insert(
        0,
        '${DateTime.now().toIso8601String()} - Biometric ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> toggle2FA(String email, bool enabled) async {
    final profile = _userProfiles[email];
    if (profile == null) return;
    profile.is2FAEnabled = enabled;
    profile.activities.insert(
        0,
        '${DateTime.now().toIso8601String()} - 2FA ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    final client = await _ensureClient();
    if (client == null) return false;
    try {
      await client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Password reset error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  UserProfile? getUserProfile(String email) {
    return _userProfiles[email];
  }
}

class UserProfile {
  final String email;
  String name;
  final String salt;
  bool is2FAEnabled;
  bool isBiometricEnabled;
  List<String> activities;
  String? lastLogin;
  String? lockUntil;

  UserProfile({
    required this.email,
    required this.name,
    required this.salt,
    required this.is2FAEnabled,
    required this.isBiometricEnabled,
    required this.activities,
    this.lastLogin,
    this.lockUntil,
  });
}
