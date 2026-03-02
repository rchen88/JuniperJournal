import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/supabase_database.dart';
import 'package:flutter/material.dart';

/// Service class that handles all authentication operations using Supabase Auth.
///
/// This class provides methods for:
/// - Email/password authentication (login, signup, logout)
/// - OAuth providers (Google, etc.)
/// - Password reset
/// - User session management
///
/// All methods return a response object or throw exceptions that should be
/// handled by the UI layer.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => SupabaseDatabase.instance.client;

  /// Returns the currently logged-in user, or null if not authenticated
  User? get currentUser => _client.auth.currentUser;

  /// Listen to auth state changes
  ///
  /// Returns a stream that emits whenever the auth state changes
  /// (login, logout, token refresh, etc.)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get the current user's session
  ///
  /// Returns null if no active session
  Session? get currentSession => _client.auth.currentSession;


  /// Returns true if a user is currently logged in
  bool get isLoggedIn => currentUser != null;

  void logCurrentUser() {
    assert(() {
      debugPrint('Current user: ${currentUser?.email} (${currentUser?.id})');
      return true;
    }());
  }
  /// Sign up a new user with email and password
  ///
  /// Throws an exception if signup fails
  /// Returns the user object on success
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );
    return SignUpResult(
      user: response.user,
      session: response.session,
      requiresEmailConfirmation: response.session == null,
    );
  }

  /// Sign in an existing user with email and password
  ///
  /// Throws an exception if login fails
  /// Returns the user object on success
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.user;
  }

  /// Sign in with Google OAuth
  ///
  /// Opens browser for Google authentication
  /// Throws an exception if OAuth fails
  Future<bool> signInWithGoogle() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutterquickstart://login-callback/',
    );

    return response;
  }

  /// Sign out the current user
  ///
  /// Throws an exception if logout fails
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send a password reset email to the user
  ///
  /// Throws an exception if the request fails
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update the current user's password
  ///
  /// Requires the user to be logged in
  /// Throws an exception if update fails
  Future<User?> updatePassword(String newPassword) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    return response.user;
  }

  /// Update the current user's profile metadata (avatar, visibility, etc.)
  Future<User?> updateProfile({
    String? avatarUrl,
    bool? isPublicProfile,
  }) async {
    final data = <String, dynamic>{};
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (isPublicProfile != null) data['is_public_profile'] = isPublicProfile;
    if (data.isEmpty) return currentUser;

    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );
      return response.user;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return null;
    }
  }

  /// Refresh the current session
  ///
  /// Useful for keeping the user logged in
  Future<Session?> refreshSession() async {
    final response = await _client.auth.refreshSession();
    return response.session;
  }

  /// Permanently deletes the current user's account via a Postgres RPC function.
  /// Requires the `delete_user` function to exist in the database (see docs).
  Future<bool> deleteAccount() async {
    try {
      await _client.rpc('delete_user');
      await _client.auth.signOut();
      return true;
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return false;
    }
  }
}

/// Result object returned from signup
class SignUpResult {
  final User? user;
  final Session? session;
  final bool requiresEmailConfirmation;

  /// If non-null, signup failed and this is the user-friendly error
  final String? friendlyErrorMessage;

  /// Optional raw values for debugging/logging
  final String? rawErrorCode;
  final int? rawStatusCode;

  const SignUpResult({
    required this.user,
    required this.session,
    required this.requiresEmailConfirmation,
    this.friendlyErrorMessage,
    this.rawErrorCode,
    this.rawStatusCode,
  });

  bool get isSuccess => friendlyErrorMessage == null;
}