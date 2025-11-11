import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as domain;

/// Authentication service for handling user authentication
abstract class AuthService {
  /// Get the current authenticated user
  domain.User? get currentUser;

  /// Stream of authentication state changes
  Stream<domain.User?> get authStateChanges;

  /// Sign in with email and password
  Future<domain.User?> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<domain.User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Sign in with Google
  Future<bool> signInWithGoogle();

  /// Sign out the current user
  Future<void> signOut();

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Reset password (legacy method)
  Future<void> resetPassword(String email);

  /// Send OTP to email for password reset
  Future<void> sendPasswordResetOtp(String email);

  /// Verify OTP and update password
  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
}

/// Supabase implementation of AuthService
class AuthServiceImpl implements AuthService {
  final SupabaseClient _supabaseClient;
  late final Stream<domain.User?> _authStateStream;

  AuthServiceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient {
    // Create a stream that starts with the current user and then listens to auth changes
    _authStateStream = Stream.value(currentUser).asyncExpand((initialUser) async* {
      yield initialUser;

      await for (final data in _supabaseClient.auth.onAuthStateChange) {
        final session = data.session;
        if (session != null) {
          final user = _mapSupabaseUserToDomain(session.user);
          yield user;
        } else {
          yield null;
        }
      }
    }).asBroadcastStream();
  }

  domain.User? _mapSupabaseUserToDomain(User supabaseUser) {
    return domain.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      name: supabaseUser.userMetadata?['name'] ?? supabaseUser.email ?? 'User',
      photoUrl: supabaseUser.userMetadata?['avatar_url'],
      createdAt: DateTime.parse(supabaseUser.createdAt),
    );
  }

  @override
  domain.User? get currentUser {
    final supabaseUser = _supabaseClient.auth.currentUser;
    if (supabaseUser == null) return null;
    return _mapSupabaseUserToDomain(supabaseUser);
  }

  @override
  Stream<domain.User?> get authStateChanges => _authStateStream;

  @override
  Future<domain.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return _mapSupabaseUserToDomain(response.user!);
      }
      return null;
    } catch (e) {
      // Error signing in
      rethrow;
    }
  }

  @override
  Future<domain.User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        return _mapSupabaseUserToDomain(response.user!);
      }
      return null;
    } catch (e) {
      // Error signing up
      rethrow;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Need to specify the redirect URL to come back to the app
        // Use the current page origin (works for localhost and GitHub Pages)
        final origin = Uri.base.origin;
        final path = Uri.base.path;

        // Build full redirect URL
        // For GitHub Pages: https://ariancamejo.github.io/lucio_sales/
        // For localhost: http://localhost:PORT/
        final redirectUrl = path.isNotEmpty && path != '/'
            ? '$origin$path'
            : origin;

        print('🌐 [Auth] Web OAuth redirect URL: $redirectUrl');

        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
      } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        // Mobile/Desktop: use custom scheme
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.luciosales://login-callback/',
        );
      } else {
        // Windows/Linux: default behavior
        await _supabaseClient.auth.signInWithOAuth(
          OAuthProvider.google,
        );
      }
      return true;
    } catch (e) {
      print('❌ [Auth] Error signing in with Google: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      // Error signing out
      rethrow;
    }
  }

  @override
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      // Error resetting password
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // No redirect needed for OTP
      );
    } catch (e) {
      // Error sending OTP
      rethrow;
    }
  }

  @override
  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      print('🔑 Attempting to verify OTP for email: $email');
      print('🔑 Token: $token');

      // Verify the OTP token
      final response = await _supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      print('🔑 OTP verification response: ${response.session != null ? "Session created" : "No session"}');

      if (response.session == null) {
        throw Exception('Invalid or expired code');
      }

      print('🔑 Updating password...');
      // Update the password
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('🔑 Password updated successfully');

      // Sign out after password reset
      await _supabaseClient.auth.signOut();

      print('🔑 Signed out after password reset');
    } catch (e) {
      // Error verifying OTP or resetting password
      print('❌ Error in verifyOtpAndResetPassword: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    // No need to close the stream as it's managed automatically
  }
}
