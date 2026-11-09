// lib/features/payroll/data/models/payroll_model.dart

class PayrollModel {
  // ── Status Constants ──────────────────────────────────────────
  static const String statusPending   = 'PENDING';
  static const String statusPaid      = 'PAID';
  static const String statusCancelled = 'CANCELLED';
  static const List<String> statuses = [statusPending, statusPaid, statusCancelled];

  final int? id;
  final String? employeeId;
  final String monthYear;
  final double baseSalary;
  final double bonus;
  final double deductions;
  final double netSalary;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  PayrollModel({
    this.id,
    this.employeeId,
    required this.monthYear,
    required this.baseSalary,
    required this.bonus,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'] as int?,
      employeeId: json['employee_id']?.toString(),
      monthYear: json['month_year'] ?? '',
      baseSalary: (json['base_salary'] as num?)?.toDouble() ?? 0.0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] ?? statusPending).toString().toUpperCase(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'month_year': monthYear,
      'base_salary': baseSalary,
      'bonus': bonus,
      'deductions': deductions,
    };
  }

  PayrollModel copyWith({
    int? id,
    String? employeeId,
    String? monthYear,
    double? baseSalary,
    double? bonus,
    double? deductions,
    double? netSalary,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return PayrollModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      monthYear: monthYear ?? this.monthYear,
      baseSalary: baseSalary ?? this.baseSalary,
      bonus: bonus ?? this.bonus,
      deductions: deductions ?? this.deductions,
      netSalary: netSalary ?? this.netSalary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
