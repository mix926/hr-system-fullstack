// lib/core/rbac/auth_session.dart
//
// AuthSession — in-memory singleton that mirrors the authenticated
// user's identity and token.
//
// Design goals:
//   • Single source of truth for "who is logged in" (role, id, email).
//   • UI guards read it synchronously without async SharedPreferences lookups.
//   • SecureApiClient reads the token + role to enforce endpoint permissions.
//   • Survives hot-reload; cleared on logout / token expiry.
//
// Lifecycle:
//   1. After successful login → AuthSession.instance.startSession(...)
//   2. On app start → AuthSession.instance.restore() reads from SharedPreferences
//   3. On logout  → AuthSession.instance.clear()

import 'package:shared_preferences/shared_preferences.dart';

import 'permission.dart';
import 'user_role.dart';

class AuthSession {
  // ── Singleton ──────────────────────────────────────────────────
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  // ── State ──────────────────────────────────────────────────────
  String? _token;
  String? _userId;
  String? _email;
  String? _firstName;
  String? _lastName;
  UserRole _role = UserRole.staff;
  bool _isActive = false;

  // Getters ──────────────────────────────────────────────────────
  String? get token      => _token;
  String? get userId     => _userId;
  String? get email      => _email;
  String? get firstName   => _firstName;
  String? get lastName    => _lastName;
  String  get displayName => '${_firstName ?? ''} ${_lastName ?? ''}'.trim();
  String  get initials {
    if (_firstName != null && _firstName!.isNotEmpty) {
      final last = _lastName != null && _lastName!.isNotEmpty
          ? _lastName![0]
          : '';
      return '${_firstName![0]}$last'.toUpperCase();
    }
    return _email != null && _email!.isNotEmpty
        ? _email![0].toUpperCase()
        : 'U';
  }

  UserRole get role      => _role;
  bool     get isActive  => _isActive;
  bool     get isLoggedIn => _isActive && _token != null;

  // ── Permission shortcut ───────────────────────────────────────
  bool hasPermission(Permission permission) => _role.hasPermission(permission);

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Hydrate session state after a successful login.
  void startSession({
    required String token,
    required UserRole role,
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
  }) {
    _token     = token;
    _role      = role;
    _userId    = userId;
    _email     = email;
    _firstName = firstName;
    _lastName  = lastName;
    _isActive  = true;
  }

  /// Restore session from SharedPreferences on app startup.
  /// Returns `true` if a valid token was found.
  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) return false;

    _token     = token;
    _userId    = prefs.getString('user_id');
    _email     = prefs.getString('email');
    _firstName = prefs.getString('first_name');
    _lastName  = prefs.getString('last_name');
    _role      = UserRole.fromString(prefs.getString('role'));
    _isActive  = true;
    return true;
  }

  /// Persist current session fields to SharedPreferences.
  /// Called by AuthBloc after login.
  Future<void> persist({
    required String token,
    required UserRole role,
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('role', role.value);
    await prefs.setString('user_id', userId);
    await prefs.setString('email', email);
    if (firstName != null) await prefs.setString('first_name', firstName);
    if (lastName != null) await prefs.setString('last_name', lastName);

    startSession(
      token: token,
      role: role,
      userId: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Clear all session state and persisted credentials.
  Future<void> clear() async {
    _token     = null;
    _userId    = null;
    _email     = null;
    _firstName = null;
    _lastName  = null;
    _role      = UserRole.staff;
    _isActive  = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
