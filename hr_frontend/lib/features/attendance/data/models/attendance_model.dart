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
}