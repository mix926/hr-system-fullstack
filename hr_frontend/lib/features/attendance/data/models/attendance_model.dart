class AttendanceModel {
  final int? id;
  final int? employeeId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;

  AttendanceModel({
    this.id,
    this.employeeId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      employeeId: json['employee_id'],
      date: json['date'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'status': status,
    };
  }

  AttendanceModel copyWith({
    int? id,
    int? employeeId,
    String? date,
    String? checkInTime,
    String? checkOutTime,
    String? status,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
    );
  }
}