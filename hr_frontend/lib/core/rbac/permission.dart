// lib/core/rbac/permission.dart
//
// Fine-grained permission constants used across the app.
// Each maps to a specific business action, not an HTTP verb,
// so the UI and API layers share a single vocabulary.

/// Every permission the HR system recognises.
///
/// Add new entries here and update [UserRole.permissions] — the rest
/// of the RBAC layer (guards, SecureApiClient, AuthBloc) reads from
/// that matrix automatically.
enum Permission {
  // ── Employee management ──────────────────────────────────────
  employeeCreate,
  employeeReadAll,
  employeeReadOwn,
  employeeUpdate,
  employeeDelete,

  // ── Department management ────────────────────────────────────
  departmentCreate,
  departmentRead,
  departmentUpdate,
  departmentDelete,

  // ── Leave management ──────────────────────────────────────────
  leaveCreate,
  leaveReadAll,
  leaveReadOwn,
  leaveApprove,          // approve / reject
  leaveDelete,

  // ── Attendance ───────────────────────────────────────────────
  attendanceClockIn,
  attendanceReadAll,
  attendanceReadOwn,

  // ── Performance reviews ──────────────────────────────────────
  performanceCreate,
  performanceReadAll,
  performanceReadOwn,
  performanceUpdate,
  performanceDelete,

  // ── Payroll ───────────────────────────────────────────────────
  payrollCreate,
  payrollReadAll,
  payrollReadOwn,
  payrollUpdate,
  payrollDelete,

  // ── Dashboard / stats ────────────────────────────────────────
  dashboardViewStats,

  // ── Admin & Security ─────────────────────────────────────────
  adminViewAuditLogs,     // view + export audit logs
  adminManageCompanies,   // CRUD companies
  adminManageBranches,    // CRUD branches
  adminViewSystemStats,   // view system-wide counters
}
