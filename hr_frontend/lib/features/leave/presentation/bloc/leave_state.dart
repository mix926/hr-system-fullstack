// Location: lib/features/leave/presentation/bloc/leave_state.dart
import 'package:flutter/foundation.dart';
import '../../data/models/leave_model.dart';

@immutable
abstract class LeaveState {}

class LeaveInitialState extends LeaveState {}

class LeaveLoadingState extends LeaveState {}

class LeaveLoadedState extends LeaveState {
  final List<LeaveModel> leaves;
  LeaveLoadedState(this.leaves);
}

class LeaveOperationSuccessState extends LeaveState {
  final String message;
  LeaveOperationSuccessState(this.message);
}

class LeaveErrorState extends LeaveState {
  final String message;
  LeaveErrorState(this.message);
}