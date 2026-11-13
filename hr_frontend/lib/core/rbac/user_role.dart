// lib/core/rbac/user_role.dart
//
// UserRole enum + permission matrix.
// This is the single source of truth for "which role can do what".
// UI guards and the SecureApiClient both consult [UserRole.permissions].

import 'permission.dart';

/// Roles recognised by the HR system.
///
/// The string values must match the backend `RoleEnum` exactly
/// ("ADMIN", "MANAGER", "STAFF") so JWT round-trips stay consistent.
enum UserRole {
  admin,
  manager,
  staff;

  // ── Conversion helpers ────────────────────────────────────────

  /// Parse a raw string (from JWT or SharedPreferences) into a [UserRole].
  /// Falls back to [staff] for unknown / null values — safest default.
  static UserRole fromString(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'ADMIN':
        return admin;
      case 'MANAGER':
        return manager;
      default:
        return staff;
    }
  }

  /// Serialise back to the wire format expected by the backend.
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.manager:
        return 'MANAGER';
      case UserRole.staff:
        return 'STAFF';
    }
  }

  // ── Permission matrix ─────────────────────────────────────────
  //
  // Returns the set of permissions granted to this role.
  // If a permission is NOT listed here, it is denied everywhere.
  List<Permission> get permissions {
    switch (this) {
      case UserRole.admin:
        return const [
          // Admin = everything
          Permission.employeeCreate,
          Permission.employeeReadAll,
          Permission.employeeReadOwn,
          Permission.employeeUpdate,
          Permission.employeeDelete,
          Permission.departmentCreate,
          Permission.departmentRead,
          Permission.departmentUpdate,
          Permission.departmentDelete,
          Permission.leaveCreate,
          Permission.leaveReadAll,
          Permission.leaveReadOwn,
          Permission.leaveApprove,
          Permission.leaveDelete,
          Permission.attendanceClockIn,
          Permission.attendanceReadAll,
          Permission.attendanceReadOwn,
          Permission.performanceCreate,
          Permission.performanceReadAll,
          Permission.performanceReadOwn,
          Permission.performanceUpdate,
          Permission.performanceDelete,
          Permission.payrollCreate,
          Permission.payrollReadAll,
          Permission.payrollReadOwn,
          Permission.payrollUpdate,
          Permission.payrollDelete,
          Permission.dashboardViewStats,
          // Admin-only capabilities
          Permission.adminViewAuditLogs,
          Permission.adminManageCompanies,
          Permission.adminManageBranches,
          Permission.adminViewSystemStats,
        ];

      case UserRole.manager:
        return const [
          // Manager = read everything, approve leaves, manage reviews
          Permission.employeeReadAll,
          Permission.employeeReadOwn,
          Permission.departmentRead,
          Permission.leaveCreate,
          Permission.leaveReadAll,
          Permission.leaveReadOwn,
          Permission.leaveApprove,
          Permission.attendanceClockIn,
          Permission.attendanceReadAll,
          Permission.attendanceReadOwn,
          Permission.performanceCreate,
          Permission.performanceReadAll,
          Permission.performanceReadOwn,
          Permission.performanceUpdate,
          Permission.payrollReadAll,
          Permission.payrollReadOwn,
          Permission.dashboardViewStats,
          // Managers can view system stats (matches backend _require_admin_or_manager)
          Permission.adminViewSystemStats,
        ];

      case UserRole.staff:
        return const [
          // Staff = own data only
          Permission.employeeReadOwn,
          Permission.leaveCreate,
          Permission.leaveReadOwn,
          Permission.attendanceClockIn,
          Permission.attendanceReadOwn,
          Permission.performanceReadOwn,
          Permission.payrollReadOwn,
        ];
    }
  }

  // ── Convenience checkers ──────────────────────────────────────

  /// Returns `true` if this role has [permission].
  bool hasPermission(Permission permission) =>
      permissions.contains(permission);

  /// Returns `true` if this role has **every** permission in [perms].
  bool hasAll(Iterable<Permission> perms) =>
      perms.every(hasPermission);

  /// Returns `true` if this role has **any** of the permissions in [perms].
  bool hasAny(Iterable<Permission> perms) =>
      perms.any(hasPermission);
}
