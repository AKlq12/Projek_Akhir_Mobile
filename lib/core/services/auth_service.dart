import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

/// Handles all authentication logic for FitPro:
/// - Supabase email/password sign-in & sign-up
/// - JWT session management (auto-refresh via Supabase SDK)
/// - Biometric authentication (fingerprint / face ID)
/// - Secure credential storage for biometric quick-login
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  // Secure storage keys
  static const _emailKey = 'fitpro_user_email';
  static const _passwordKey = 'fitpro_user_password';
  static const _biometricEnabledKey = 'fitpro_biometric_enabled';

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION & USER
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the current Supabase session, if any.
  Session? get currentSession => _supabase.auth.currentSession;

  /// Returns the current Supabase auth user, if any.
  User? get currentUser => _supabase.auth.currentUser;

  /// Whether the user is currently signed in with a valid session.
  bool get isSignedIn => currentSession != null;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a new account with email/password and inserts a profile row.
  ///
  /// Returns a [UserModel] on success, throws on failure.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // 1. Create Supabase auth user
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      final user = response.user;
      if (user == null) {
        throw AuthException('Registration failed. Please try again.');
      }

      // 2. Profile row is auto-inserted via Supabase trigger (handle_new_user)
      // so we don't need to manually upsert the profile here.

      // 3. Store credentials securely for biometric re-login
      await _storeCredentials(email.trim(), password);

      // 4. Return user model
      return UserModel(
        id: user.id,
        email: email.trim(),
        fullName: fullName.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  /// Verifies the OTP sent to email for signup confirmation.
  Future<UserModel> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: email.trim(),
        token: token.trim(),
      );

      final user = response.user;
      if (user == null) {
        throw AuthException('Verification failed.');
      }

      // Fetch profile (which should have been created by trigger)
      return await fetchProfile(user.id);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Verification failed: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN IN (Email/Password)
  // ─────────────────────────────────────────────────────────────────────────

  /// Signs in with email/password. Returns [UserModel] on success.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw AuthException('Login failed. Please check your credentials.');
      }

      // Store credentials for biometric
      await _storeCredentials(email.trim(), password);

      // Fetch profile
      return await fetchProfile(user.id);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BIOMETRIC AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Checks if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Returns a list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting biometrics: $e');
      return [];
    }
  }

  /// Whether biometric login has been enabled by the user.
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Toggles biometric login on/off.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Signs in using biometric authentication.
  ///
  /// First authenticates biometrically, then uses stored credentials
  /// to sign in with Supabase.
  Future<UserModel> signInWithBiometric() async {
    try {
      // 1. Authenticate biometrically
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in to FitPro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        throw AuthException('Biometric authentication failed.');
      }

      // 2. Read stored credentials
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (email == null || password == null) {
        throw AuthException(
          'No stored credentials. Please sign in with email first.',
        );
      }

      // 3. Sign in with stored credentials
      return await signIn(email: email, password: password);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Biometric sign in failed: ${e.toString()}');
    }
  }

  /// Whether there are stored credentials for biometric login.
  Future<bool> hasStoredCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    return email != null && password != null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches the user's profile from the `profiles` table.
  Future<UserModel> fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Merge email from auth user
      final email = currentUser?.email ?? '';
      return UserModel.fromJson({...data, 'email': email});
    } catch (e) {
      // If profile doesn't exist yet, return a minimal model
      return UserModel(
        id: userId,
        email: currentUser?.email ?? '',
        fullName: currentUser?.email?.split('@').first ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Updates the user's profile.
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      await _supabase
          .from('profiles')
          .update(user.toJson())
          .eq('id', user.id);

      return await fetchProfile(user.id);
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  /// Uploads a profile picture to Supabase Storage and updates the user profile.
  Future<UserModel> uploadAvatar({
    required String userId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    try {
      final fileName = 'avatar_$userId.${fileExtension.replaceAll('.', '')}';
      final path = fileName; // Upload directly to bucket root or specific folder

      // 1. Upload to Supabase Storage (using upsert to overwrite existing)
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Get public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      // 3. Update profile row with the new URL
      // We append a timestamp to the URL to bust cache if the filename is the same
      final timestampedUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase
          .from('profiles')
          .update({'avatar_url': timestampedUrl})
          .eq('id', userId);

      // 4. Return updated profile
      return await fetchProfile(userId);
    } catch (e) {
      throw AuthException('Failed to upload avatar: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────────────────

  /// Signs out the current user and clears session.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Signs out and clears all stored credentials (full reset).
  Future<void> signOutAndClearCredentials() async {
    await signOut();
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────────────────────────────────

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw AuthException('Failed to send reset email: ${e.toString()}');
    }
  }

  /// Updates the user's password.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AuthException('Failed to update password: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Stores email/password securely for biometric re-login.
  Future<void> _storeCredentials(String email, String password) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
  }
}
