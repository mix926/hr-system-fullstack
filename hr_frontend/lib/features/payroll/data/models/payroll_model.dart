class PayrollModel {
  final int? id;
  final int? employeeId;
  final String monthYear;
  final double baseSalary;
  final double bonus;
  final double deductions;
  final double netSalary;
  final String status;

  PayrollModel({
    this.id,
    this.employeeId,
    required this.monthYear,
    required this.baseSalary,
    required this.bonus,
    required this.deductions,
    required this.netSalary,
    required this.status,
  });

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      id: json['id'],
      employeeId: json['employee_id'],
      monthYear: json['month_year'],
      baseSalary: (json['base_salary'] as num).toDouble(),
      bonus: (json['bonus'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      netSalary: (json['net_salary'] as num).toDouble(),
      status: json['status'],
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
}