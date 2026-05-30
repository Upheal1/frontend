import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/supabase_auth_service.dart';

class AuthModel extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SupabaseAuthService _supabaseAuthService = SupabaseAuthService();

  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  Map<String, int> _failedAttempts = {};
  Map<String, UserProfile> _userProfiles = {};
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get accessToken => _supabaseAuthService.currentAccessToken;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get errorMessage => _errorMessage;

  AuthModel() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _syncFromSupabaseUser();
    _supabaseAuthService.authStateChanges.listen((_) {
      _syncFromSupabaseUser();
      notifyListeners();
    }, onError: (Object error) {
      if (kDebugMode) debugPrint('Supabase auth stream error: $error');
    });
  }

  void _syncFromSupabaseUser() {
    final user = _supabaseAuthService.currentUser;
    if (user == null) {
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _userName = null;
      return;
    }

    _isAuthenticated = true;
    _userId = user.id;
    _userEmail = user.email;
    _userName = user.userMetadata?['display_name'] as String?;
    final email = user.email;
    if (email != null && !_userProfiles.containsKey(email)) {
      _userProfiles[email] = UserProfile(
        email: email,
        name: _userName ?? '',
        salt: _generateSalt(),
        isBiometricEnabled: false,
        activities: [],
      );
    }
  }

  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
    try {
      final response = await _supabaseAuthService.createUserWithEmailAndPassword(
        email,
        password,
        displayName: name,
      );
      if (response.user != null) {
        _userProfiles[email] = UserProfile(
          email: email,
          name: name,
          salt: _generateSalt(),
          isBiometricEnabled: false,
          activities: ['Signed up'],
        );
        _syncFromSupabaseUser();
        _userEmail = email;
        _userName = name;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Failed to create account';
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Signup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool?> login(String email, String password) async {
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

      final response = await _supabaseAuthService
          .signInWithEmailAndPassword(email, password);

      if (response.session != null && response.user != null) {
        _failedAttempts[email] = 0;
        await _storage.delete(key: 'lock_$email');

        final profile = _userProfiles[email];
        profile?.lastLogin = DateTime.now().toIso8601String();
        profile?.activities
            .insert(0, '${DateTime.now().toIso8601String()} - Successful login');

        _syncFromSupabaseUser();
        _userEmail = email;
        _userName = _userName ?? _userProfiles[email]?.name ?? '';
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Invalid email or password';
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil =
        DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
        await _storage.write(key: 'lock_$email', value: lockUntil);
        if (!_userProfiles.containsKey(email)) {
          _userProfiles[email] = UserProfile(
            email: email,
            name: '',
            salt: _generateSalt(),
            isBiometricEnabled: false,
            activities: [],
          );
        }
        _userProfiles[email]?.lockUntil = lockUntil;
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _supabaseAuthService.signOut();
    _isAuthenticated = false;
    _userId = null;
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

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseAuthService.sendPasswordResetEmail(email);
    _userProfiles[email]?.activities.insert(
        0, '${DateTime.now().toIso8601String()} - Password reset requested');
  }

  UserProfile? getUserProfile(String email) {
    return _userProfiles[email];
  }
}

class UserProfile {
  final String email;
  String name;
  final String salt;
  bool isBiometricEnabled;
  List<String> activities;
  String? lastLogin;
  String? lockUntil;

  UserProfile({
    required this.email,
    required this.name,
    required this.salt,
    required this.isBiometricEnabled,
    required this.activities,
    this.lastLogin,
    this.lockUntil,
  });
}
