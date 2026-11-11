// lib/core/rbac/role_guard.dart
//
// RoleGuard — a declarative widget that conditionally shows its child
// based on the current user's permissions.
//
// Usage in screens:
//   RoleGuard(
//     permission: Permission.employeeCreate,
//     child: FilledButton(onPressed: _addEmployee, child: Text('Add Employee')),
//   )
//
//   // Require multiple permissions:
//   RoleGuard.all(
//     permissions: [Permission.employeeDelete, Permission.employeeUpdate],
//     child: _buildDangerZone(),
//   )
//
//   // Show a fallback when denied:
//   RoleGuard(
//     permission: Permission.payrollReadAll,
//     child: _buildPayrollList(),
//     fallback: Text('You cannot access payroll'),
//   )

import 'package:flutter/widgets.dart';

import 'auth_session.dart';
import 'permission.dart';
import 'user_role.dart';

class RoleGuard extends StatelessWidget {
  /// Single-permission check.
  const RoleGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  })  : _permissions = null,
        _requireAll = false;

  /// Show [child] only if the current role has **every** permission in
  /// [permissions].  Otherwise show [fallback] (or nothing).
  const RoleGuard.all({
    super.key,
    required List<Permission> permissions,
    required this.child,
    this.fallback,
  })  : _permissions = permissions,
        _requireAll = true,
        permission = Permission.employeeReadOwn; // dummy, unused in this mode

  /// Show [child] only if the current role has **any** of [permissions].
  /// Otherwise show [fallback] (or nothing).
  const RoleGuard.any({
    super.key,
    required List<Permission> permissions,
    required this.child,
    this.fallback,
  })  : _permissions = permissions,
        _requireAll = false,
        permission = Permission.employeeReadOwn; // dummy, unused in this mode

  final Permission permission;
  final Widget child;
  final Widget? fallback;

  // Multi-permission mode (null = single-permission mode).
  final List<Permission>? _permissions;
  final bool _requireAll;

  @override
  Widget build(BuildContext context) {
    final role = AuthSession.instance.role;
    final perms = _permissions;
    final bool allowed;

    if (perms != null && perms.isNotEmpty) {
      allowed = _requireAll ? role.hasAll(perms) : role.hasAny(perms);
    } else {
      allowed = role.hasPermission(permission);
    }

    if (!allowed) return fallback ?? const SizedBox.shrink();
    return child;
  }
}

/// Convenience: show [child] only when role is [roles].
/// Use for coarse UI gating where specific permissions are overkill.
class RoleOnly extends StatelessWidget {
  final Set<UserRole> roles;
  final Widget child;
  final Widget? fallback;

  const RoleOnly({
    super.key,
    required this.roles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (!roles.contains(AuthSession.instance.role)) {
      return fallback ?? const SizedBox.shrink();
    }
    return child;
  }
}
