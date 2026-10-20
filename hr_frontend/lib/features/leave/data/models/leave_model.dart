// Location: lib/features/leave/data/models/leave_model.dart

class LeaveModel {
  // Leave type constants
  static const String typeAnnual = 'Annual Leave';
  static const String typeSick = 'Sick Leave';
  static const String typeUnpaid = 'Unpaid Leave';
  static const String typeMaternity = 'Maternity Leave';
  static const String typePaternity = 'Paternity Leave';

  static const List<String> leaveTypes = [
    typeAnnual,
    typeSick,
    typeUnpaid,
    typeMaternity,
    typePaternity,
  ];
  // ខ្មែរ: Backend ប្រើ UUID (String) ជា Primary Key ដូច្នេះប្រើ String? មិនមែន int?
  final String? id;
  final String? employeeId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String? reason;
  final String status;
  // ខ្មែរ: ឈ្មោះបុគ្គលិក (សម្រាប់បង្ហាញឱ្យ ADMIN/MANAGER)
  final String? employeeName;

  LeaveModel({
    this.id,
    this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
    this.employeeName,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    // ខ្មែរ: ព្យាយាម compose ឈ្មោះបុគ្គលិកពី nested employee object (ប្រសិនបើ backend return)
    String? name;
    if (json['employee'] != null) {
      final emp = json['employee'] as Map<String, dynamic>;
      final first = emp['first_name'] ?? '';
      final last  = emp['last_name']  ?? '';
      name = '$first $last'.trim();
    }
    return LeaveModel(
      id:           json['id']?.toString(),
      employeeId:   json['employee_id']?.toString(),
      leaveType:    json['leave_type'],
      startDate:    json['start_date'],
      endDate:      json['end_date'],
      reason:       json['reason'],
      status:       json['status'],
      employeeName: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
    };
  }
}