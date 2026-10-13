// Location: lib/features/leave/presentation/bloc/leave_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/leave_api_service.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final LeaveApiService _apiService;

  LeaveBloc(this._apiService) : super(LeaveInitialState()) {
    on<LoadLeavesEvent>(_onLoadLeaves);
    on<CreateLeaveEvent>(_onCreateLeave);
    on<UpdateLeaveStatusEvent>(_onUpdateStatus);
  }

  Future<void> _onLoadLeaves(LoadLeavesEvent event, Emitter<LeaveState> emit) async {
    emit(LeaveLoadingState());
    final result = await _apiService.getLeaves();

    result.fold(
      (failure) => emit(LeaveErrorState(failure.message)),
      (leaves) => emit(LeaveLoadedState(leaves)),
    );
  }

  Future<void> _onCreateLeave(CreateLeaveEvent event, Emitter<LeaveState> emit) async {
    emit(LeaveLoadingState());
    final result = await _apiService.createLeave(event.leave);

    result.fold(
      (failure) => emit(LeaveErrorState(failure.message)),
      (success) {
        emit(LeaveOperationSuccessState('ស្នើសុំច្បាប់បានជោគជ័យ!'));
        add(LoadLeavesEvent());
      },
    );
  }

  Future<void> _onUpdateStatus(UpdateLeaveStatusEvent event, Emitter<LeaveState> emit) async {
    final result = await _apiService.updateLeaveStatus(event.leaveId, event.status);
    result.fold(
      (failure) => emit(LeaveErrorState(failure.message)),
      (success) {
        final label = event.status == 'APPROVED' ? 'អនុម័តបានជោគជ័យ!' : 'បដិសេធបានជោគជ័យ!';
        emit(LeaveOperationSuccessState(label));
        add(LoadLeavesEvent());
      },
    );
  }
}