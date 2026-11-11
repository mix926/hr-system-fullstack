// lib/features/auth/presentation/bloc/auth_bloc.dart
//
// AuthBloc — the single source of truth for authentication state.
//
// Listened to at the root of the widget tree to decide whether to show
// the login screen or the main app.  UI guards and the SecureApiClient
// read from AuthSession (which this bloc keeps in sync).

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/rbac/auth_session.dart';
import '../../../../core/rbac/user_role.dart';
import '../../data/auth_api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApiService _authApiService;

  AuthBloc(this._authApiService) : super(AuthInitial()) {
    on<AuthSessionRestored>(_onRestoreSession);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLoginSucceeded>(_onLoginSucceeded);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // ── Restore from SharedPreferences on app startup ─────────────
  Future<void> _onRestoreSession(
    AuthSessionRestored event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final ok = await AuthSession.instance.restore();
    if (ok && AuthSession.instance.isLoggedIn) {
      emit(Authenticated(
        role: AuthSession.instance.role,
        userId: AuthSession.instance.userId ?? '',
        email: AuthSession.instance.email ?? '',
        displayName: AuthSession.instance.displayName,
      ));
    } else {
      emit(Unauthenticated());
    }
  }

  // ── Login flow ────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _authApiService.login(event.email, event.password);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) {
        // data is the raw API response map
        final token = data['access_token'] as String? ?? '';
        final user = data['user'] as Map<String, dynamic>? ?? {};
        final roleStr = user['role'] as String? ?? 'STAFF';
        final role = UserRole.fromString(roleStr);

        // Persist + hydrate the singleton session
        AuthSession.instance.persist(
          token: token,
          role: role,
          userId: user['id']?.toString() ?? '',
          email: user['email']?.toString() ?? event.email,
          firstName: user['first_name']?.toString(),
          lastName: user['last_name']?.toString(),
        );

        emit(Authenticated(
          role: role,
          userId: user['id']?.toString() ?? '',
          email: user['email']?.toString() ?? event.email,
          displayName: AuthSession.instance.displayName,
        ));
      },
    );
  }

  /// Called when login succeeds outside the bloc (e.g. direct API call).
  void _onLoginSucceeded(
    AuthLoginSucceeded event,
    Emitter<AuthState> emit,
  ) {
    final role = UserRole.fromString(event.role);
    AuthSession.instance.persist(
      token: event.token,
      role: role,
      userId: event.userId,
      email: event.email,
      firstName: event.firstName,
      lastName: event.lastName,
    );
    emit(Authenticated(
      role: role,
      userId: event.userId,
      email: event.email,
      displayName: AuthSession.instance.displayName,
    ));
  }

  // ── Logout flow ───────────────────────────────────────────────
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await AuthSession.instance.clear();
    emit(Unauthenticated());
  }
}
