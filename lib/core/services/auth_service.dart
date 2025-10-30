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

  /// Reset password
  Future<void> resetPassword(String email);
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
      // Determine redirect URI based on platform
      String? redirectTo;

      if (kIsWeb) {
        // Web: use default Supabase redirect
        redirectTo = null;
      } else if (Platform.isAndroid) {
        // Android: use custom scheme
        redirectTo = 'io.supabase.luciosales://login-callback/';
      } else if (Platform.isIOS) {
        // iOS: use custom scheme
        redirectTo = 'io.supabase.luciosales://login-callback/';
      } else if (Platform.isMacOS) {
        // macOS: use custom scheme
        redirectTo = 'io.supabase.luciosales://login-callback/';
      } else if (Platform.isWindows || Platform.isLinux) {
        // Windows/Linux: use web redirect (opens browser)
        redirectTo = null;
      }

      await _supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      return true;
    } catch (e) {
      // Error signing in with Google
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

  Future<void> dispose() async {
    // No need to close the stream as it's managed automatically
  }
}
