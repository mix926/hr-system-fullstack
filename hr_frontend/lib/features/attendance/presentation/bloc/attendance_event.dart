import 'package:flutter/foundation.dart';

@immutable
abstract class AttendanceEvent {}

/// Load all attendance records (or the current employee's own)
class LoadAttendancesEvent extends AttendanceEvent {}

/// Check in for today
class CheckInEvent extends AttendanceEvent {}

/// Check out for today
class CheckOutEvent extends AttendanceEvent {}
