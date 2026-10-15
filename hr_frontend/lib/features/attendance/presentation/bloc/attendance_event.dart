// lib/features/attendance/presentation/bloc/attendance_event.dart
import 'package:flutter/foundation.dart';

@immutable
abstract class AttendanceEvent {}

/// ទាញយកទិន្នន័យ Attendance ទាំងអស់ (ឬរបស់ Employee ខ្លួនឯង)
class LoadAttendancesEvent extends AttendanceEvent {}

/// Check-in ថ្ងៃនេះ
class CheckInEvent extends AttendanceEvent {}

/// Check-out ថ្ងៃនេះ
class CheckOutEvent extends AttendanceEvent {}
