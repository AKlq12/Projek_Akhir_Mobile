import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication state for the app.
enum AuthStatus {
  /// Initial state — checking for existing session.
  initial,

  /// Currently authenticating (sign in / sign up).
  loading,

  /// User is authenticated with a valid session.
  authenticated,

  /// Not authenticated or session expired.
  unauthenticated,

  /// An error occurred during authentication.
  error,
}

/// State management for authentication using [ChangeNotifier].
///
/// Tracks auth status, current user profile, biometric settings,
/// and error messages. Listens to Supabase auth state changes.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  AuthStatus _status = AuthStatus.initial;
  UserModel _user = UserModel.empty;
  String _errorMessage = '';
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  StreamSubscription<AuthState>? _authSubscription;

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  UserModel get user => _user;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Initializes the provider:
  /// 1. Checks for existing session
  /// 2. Checks biometric availability
  /// 3. Listens to auth state changes
  Future<void> init() async {
    _status = AuthStatus.initial;

    // Check biometric capabilities
    _biometricAvailable = await _authService.isBiometricAvailable();
    _biometricEnabled = await _authService.isBiometricEnabled();

    // Check existing session
    if (_authService.isSignedIn) {
      try {
        final userId = _authService.currentUser!.id;
        _user = await _authService.fetchProfile(userId);
        _status = AuthStatus.authenticated;
      } catch (e) {
        debugPrint('Failed to restore session: $e');
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }

    // Listen for auth state changes (e.g. token refresh, sign out)
    _authSubscription = _authService.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        _user = UserModel.empty;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.signedIn) {
        // Session refreshed — no need to re-fetch, just keep going
      }
    });

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────────────────────────────────

  /// Registers a new user with email, password, and name.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = '';
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTP VERIFICATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Verifies OTP for signup code
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    _setLoading();

    try {
      _user = await _authService.verifyOtp(email: email, token: token);
      _status = AuthStatus.authenticated;
      _errorMessage = '';
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────────────────────────────────────

  /// Signs in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();

    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = '';
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BIOMETRIC SIGN IN
  // ─────────────────────────────────────────────────────────────────────────

  /// Signs in using biometric authentication (fingerprint / face ID).
  Future<bool> signInWithBiometric() async {
    _setLoading();

    try {
      _user = await _authService.signInWithBiometric();
      _status = AuthStatus.authenticated;
      _errorMessage = '';
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Whether there are stored credentials for biometric login.
  Future<bool> hasStoredCredentials() async {
    return _authService.hasStoredCredentials();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BIOMETRIC SETTINGS
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggles biometric login on/off.
  Future<void> toggleBiometric() async {
    _biometricEnabled = !_biometricEnabled;
    await _authService.setBiometricEnabled(_biometricEnabled);
    notifyListeners();
  }

  /// Sets biometric enabled state.
  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _authService.setBiometricEnabled(enabled);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  /// Refreshes the user profile from Supabase.
  Future<void> refreshProfile() async {
    if (_user.isEmpty) return;

    try {
      _user = await _authService.fetchProfile(_user.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }

  /// Updates the user profile.
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      _user = await _authService.updateProfile(updatedUser);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────────────────

  /// Signs out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
    _user = UserModel.empty;
    _status = AuthStatus.unauthenticated;
    _errorMessage = '';
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────────────────────────────────

  /// Sends a password reset email.
  Future<bool> resetPassword(String email) async {
    _setLoading();

    try {
      await _authService.resetPassword(email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERROR MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Clears the error message.
  void clearError() {
    _errorMessage = '';
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
