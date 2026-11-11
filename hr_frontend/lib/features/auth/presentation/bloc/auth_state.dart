// lib/features/auth/presentation/bloc/auth_state.dart
import 'package:flutter/foundation.dart';

import '../../../../core/rbac/user_role.dart';

@immutable
sealed class AuthState {}

/// Initial state — before any login attempt or session restore.
class AuthInitial extends AuthState {}

/// Session restore / login in progress.
class AuthLoading extends AuthState {}

/// User is authenticated.
class Authenticated extends AuthState {
  final UserRole role;
  final String userId;
  final String email;
  final String displayName;

  Authenticated({
    required this.role,
    required this.userId,
    required this.email,
    required this.displayName,
  });
}

/// User is not authenticated (logged out or session expired).
class Unauthenticated extends AuthState {}

/// Login failed — show [message] to the user.
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
