// lib/features/attendance/presentation/bloc/attendance_state.dart
import 'package:flutter/foundation.dart';
import '../../data/models/attendance_model.dart';

@immutable
abstract class AttendanceState {}

class AttendanceInitialState extends AttendanceState {}

class AttendanceLoadingState extends AttendanceState {}

/// ទិន្នន័យ Attendance ត្រូវបានទាញយកបានជោគជ័យ
class AttendanceLoadedState extends AttendanceState {
  final List<AttendanceModel> attendances;

  /// Attendance ថ្ងៃនេះ (null = មិនទាន់ check-in)
  final AttendanceModel? todayAttendance;

  AttendanceLoadedState({
    required this.attendances,
    this.todayAttendance,
  });
}

/// Check-in / Check-out / ជោគជ័យ
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
