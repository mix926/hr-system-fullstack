// lib/core/network/secure_api_client.dart
//
// SecureApiClient — a thin wrapper around Dio that enforces RBAC
// at the network layer.  Every API service routes its requests through
// this client instead of calling Dio directly.
//
// How it works:
//   1. The caller passes the [Permission] required for the operation.
//   2. The client checks AuthSession for the role + permission.
//   3. If denied → returns Result.failure(AccessDeniedFailure) without
//      hitting the network (fail-closed, defence-in-depth).
//   4. If allowed → delegates to Dio with the auth token attached.
//
// This means even if a UI bug exposes a button to an unauthorized user,
// the API call itself is blocked client-side before it leaves the device.
// The backend remains the final authority, but this prevents unnecessary
// network round-trips and leaked metadata.

import 'package:dio/dio.dart';

import '../errors/result.dart';
import '../rbac/auth_session.dart';
import '../rbac/permission.dart';

/// Failure thrown when the current role lacks the required permission.
class AccessDeniedFailure extends Failure {
  final Permission requiredPermission;

  AccessDeniedFailure({
    required this.requiredPermission,
  }) : super(
          message: 'Access denied: your role cannot perform this action '
              '(${requiredPermission.name}).',
          code: 'FORBIDDEN',
        );
}

/// Failure thrown when no auth token is present.
class UnauthenticatedFailure extends Failure {
  UnauthenticatedFailure()
      : super(
          message: 'You must be logged in to perform this action.',
          code: 'UNAUTHENTICATED',
        );
}

/// Thin wrapper around [Dio] that checks RBAC permissions before
/// forwarding requests to the backend.
class SecureApiClient {
  final Dio _dio;

  SecureApiClient(this._dio);

  // ── Internal guard ────────────────────────────────────────────

  /// Returns `null` if the call may proceed, or a [Failure] if blocked.
  Failure? _check(Permission? permission) {
    final session = AuthSession.instance;

    if (!session.isLoggedIn) return UnauthenticatedFailure();

    if (permission != null && !session.hasPermission(permission)) {
      return AccessDeniedFailure(requiredPermission: permission);
    }
    return null; // OK to proceed
  }

  // ── Public HTTP verbs ─────────────────────────────────────────

  Future<Result<Response>> get(
    String path, {
    Permission? permission,
    Map<String, dynamic>? queryParameters,
  }) async {
    final blocked = _check(permission);
    if (blocked != null) return Result.failure(blocked);
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      return Result.success(res);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Request failed'),
        code: e.response?.statusCode?.toString(),
      ));
    }
  }

  Future<Result<Response>> post(
    String path, {
    Permission? permission,
    dynamic data,
  }) async {
    final blocked = _check(permission);
    if (blocked != null) return Result.failure(blocked);
    try {
      final res = await _dio.post(path, data: data);
      return Result.success(res);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Request failed'),
        code: e.response?.statusCode?.toString(),
      ));
    }
  }

  Future<Result<Response>> patch(
    String path, {
    Permission? permission,
    dynamic data,
  }) async {
    final blocked = _check(permission);
    if (blocked != null) return Result.failure(blocked);
    try {
      final res = await _dio.patch(path, data: data);
      return Result.success(res);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Request failed'),
        code: e.response?.statusCode?.toString(),
      ));
    }
  }

  Future<Result<Response>> delete(
    String path, {
    Permission? permission,
  }) async {
    final blocked = _check(permission);
    if (blocked != null) return Result.failure(blocked);
    try {
      final res = await _dio.delete(path);
      return Result.success(res);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Request failed'),
        code: e.response?.statusCode?.toString(),
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _extractDetail(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString() ?? fallback;
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }
}
