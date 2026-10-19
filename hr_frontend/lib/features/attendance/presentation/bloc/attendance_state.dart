import 'package:flutter/foundation.dart';
import '../../data/models/attendance_model.dart';

@immutable
abstract class AttendanceState {}

class AttendanceInitialState extends AttendanceState {}

class AttendanceLoadingState extends AttendanceState {}

/// Attendance data loaded successfully
class AttendanceLoadedState extends AttendanceState {
  final List<AttendanceModel> attendances;

  /// Today's attendance (null = not checked in yet)
  final AttendanceModel? todayAttendance;

  AttendanceLoadedState({
    required this.attendances,
    this.todayAttendance,
  });
}

/// Check-in / Check-out / Operation success
class AttendanceOperationSuccessState extends AttendanceState {
  final String message;
  final AttendanceModel attendance;

  AttendanceOperationSuccessState({
    required this.message,
    required this.attendance,
  });
}

class AttendanceErrorState extends AttendanceState {
  final String message;
  AttendanceErrorState(this.message);
}
