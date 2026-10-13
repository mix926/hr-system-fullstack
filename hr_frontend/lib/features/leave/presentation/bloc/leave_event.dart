// Location: lib/features/leave/presentation/bloc/leave_event.dart
import 'package:flutter/foundation.dart';
// ខ្មែរ: ជួសជុលទីតាំង import ត្រឹមត្រូវ (bloc/ → ../../data/models/)
import '../../data/models/leave_model.dart';

@immutable
abstract class LeaveEvent {}

class LoadLeavesEvent extends LeaveEvent {}

class CreateLeaveEvent extends LeaveEvent {
  final LeaveModel leave;
  CreateLeaveEvent(this.leave);
}

/// ខ្មែរ: Event សម្រាប់ ADMIN/MANAGER អនុម័ត ឬ បដិសេធ
class UpdateLeaveStatusEvent extends LeaveEvent {
  final String leaveId;
  final String status; // "APPROVED" or "REJECTED"
  UpdateLeaveStatusEvent(this.leaveId, this.status);
}