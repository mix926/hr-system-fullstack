// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:flutter/foundation.dart';

@immutable
sealed class AuthEvent {}

/// Attempt to log in with [email] and [password].
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

/// Log out the current user and clear all stored credentials.
class AuthLogoutRequested extends AuthEvent {}

/// Check SharedPreferences for an existing token and restore the session.
/// Fired on app startup.
class AuthSessionRestored extends AuthEvent {}

/// Emitted by the login flow after successful authentication so the bloc
/// can update its state immediately.
class AuthLoginSucceeded extends AuthEvent {
  final String token;
  final String role;
  final String userId;
  final String email;
  final String? firstName;
  final String? lastName;

  AuthLoginSucceeded({
    required this.token,
    required this.role,
    required this.userId,
    required this.email,
    this.firstName,
    this.lastName,
  });
}
