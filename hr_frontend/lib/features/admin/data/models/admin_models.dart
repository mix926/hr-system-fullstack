// lib/features/admin/data/models/admin_models.dart
//
// Data models for the Admin & Security feature:
//   - AuditLog    (read-only record of every system action)
//   - Company     (multi-company / tenant)
//   - Branch      (branch per company)
//   - SystemStats (admin dashboard counters)

// ─── AuditLog ──────────────────────────────────────────────────

class AuditLog {
  final String id;
  final String? actorId;
  final String? actorEmail;
  final String action;       // e.g. "CREATE", "UPDATE", "DELETE", "LOGIN"
  final String entityType;
  final String? entityId;
  final String? description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? createdAt;

  const AuditLog({
    required this.id,
    this.actorId,
    this.actorEmail,
    required this.action,
    required this.entityType,
    this.entityId,
    this.description,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id:          j['id']?.toString() ?? '',
        actorId:     j['actor_id']?.toString(),
        actorEmail:  j['actor_email']?.toString(),
        action:      j['action']?.toString() ?? '',
        entityType:  j['entity_type']?.toString() ?? '',
        entityId:    j['entity_id']?.toString(),
        description: j['description']?.toString(),
        oldValues:   j['old_values'] != null
            ? Map<String, dynamic>.from(j['old_values'] as Map)
            : null,
        newValues:   j['new_values'] != null
            ? Map<String, dynamic>.from(j['new_values'] as Map)
            : null,
        ipAddress:   j['ip_address']?.toString(),
        userAgent:   j['user_agent']?.toString(),
        createdAt:   j['created_at']?.toString(),
      );
}

// ─── Company ───────────────────────────────────────────────────

class Company {
  final String id;
  final String name;
  final String? legalName;
  final String? registrationNumber;
  final String? country;
  final String timezone;
  final String currency;
  final String? logoPath;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const Company({
    required this.id,
    required this.name,
    this.legalName,
    this.registrationNumber,
    this.country,
    this.timezone = 'UTC',
    this.currency = 'USD',
    this.logoPath,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
        id:                 j['id']?.toString() ?? '',
        name:               j['name']?.toString() ?? '',
        legalName:          j['legal_name']?.toString(),
        registrationNumber: j['registration_number']?.toString(),
        country:            j['country']?.toString(),
        timezone:           j['timezone']?.toString() ?? 'UTC',
        currency:           j['currency']?.toString() ?? 'USD',
        logoPath:           j['logo_path']?.toString(),
        isActive:           j['is_active'] as bool? ?? true,
        createdAt:          j['created_at']?.toString(),
        updatedAt:          j['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name':     name,
        'timezone': timezone,
        'currency': currency,
        if (legalName          != null) 'legal_name':           legalName,
        if (registrationNumber != null) 'registration_number':  registrationNumber,
        if (country            != null) 'country':              country,
        if (logoPath           != null) 'logo_path':            logoPath,
      };
}

// ─── Branch ────────────────────────────────────────────────────

class Branch {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? email;
  final String? managerId;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const Branch({
    required this.id,
    required this.companyId,
    required this.name,
    this.code,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.email,
    this.managerId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
        id:        j['id']?.toString() ?? '',
        companyId: j['company_id']?.toString() ?? '',
        name:      j['name']?.toString() ?? '',
        code:      j['code']?.toString(),
        address:   j['address']?.toString(),
        city:      j['city']?.toString(),
        country:   j['country']?.toString(),
        phone:     j['phone']?.toString(),
        email:     j['email']?.toString(),
        managerId: j['manager_id']?.toString(),
        isActive:  j['is_active'] as bool? ?? true,
        createdAt: j['created_at']?.toString(),
        updatedAt: j['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'name':       name,
        if (code      != null) 'code':       code,
        if (address   != null) 'address':    address,
        if (city      != null) 'city':       city,
        if (country   != null) 'country':    country,
        if (phone     != null) 'phone':      phone,
        if (email     != null) 'email':      email,
        if (managerId != null) 'manager_id': managerId,
      };
}

// ─── SystemStats ───────────────────────────────────────────────

class SystemStats {
  final int totalEmployees;
  final int activeEmployees;
  final int totalDepartments;
  final int pendingLeaveRequests;
  final int totalLeaveRequests;
  final int pendingPayroll;
  final int paidPayroll;
  final int totalPayroll;
  final int openJobs;
  final int totalCandidates;
  final int auditLogsToday;

  const SystemStats({
    this.totalEmployees      = 0,
    this.activeEmployees     = 0,
    this.totalDepartments    = 0,
    this.pendingLeaveRequests = 0,
    this.totalLeaveRequests  = 0,
    this.pendingPayroll      = 0,
    this.paidPayroll         = 0,
    this.totalPayroll        = 0,
    this.openJobs            = 0,
    this.totalCandidates     = 0,
    this.auditLogsToday      = 0,
  });

  factory SystemStats.fromJson(Map<String, dynamic> j) {
    final emp  = j['employees']     as Map<String, dynamic>? ?? {};
    final leave = j['leave_requests'] as Map<String, dynamic>? ?? {};
    final pay   = j['payroll']       as Map<String, dynamic>? ?? {};
    final rec   = j['recruitment']   as Map<String, dynamic>? ?? {};
    return SystemStats(
      totalEmployees:       (emp['total']   as num? ?? 0).toInt(),
      activeEmployees:      (emp['active']  as num? ?? 0).toInt(),
      totalDepartments:     (j['departments'] as num? ?? 0).toInt(),
      totalLeaveRequests:   (leave['total']   as num? ?? 0).toInt(),
      pendingLeaveRequests: (leave['pending'] as num? ?? 0).toInt(),
      totalPayroll:         (pay['total']   as num? ?? 0).toInt(),
      pendingPayroll:       (pay['pending'] as num? ?? 0).toInt(),
      paidPayroll:          (pay['paid']    as num? ?? 0).toInt(),
      openJobs:             (rec['open_jobs']        as num? ?? 0).toInt(),
      totalCandidates:      (rec['total_candidates'] as num? ?? 0).toInt(),
      auditLogsToday:       (j['audit_logs_today'] as num? ?? 0).toInt(),
    );
  }
}
