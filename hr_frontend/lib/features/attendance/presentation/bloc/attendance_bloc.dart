// lib/features/attendance/presentation/bloc/attendance_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/attendance_api_service.dart';
import '../../data/models/attendance_model.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceApiService _apiService;

  AttendanceBloc(this._apiService) : super(AttendanceInitialState()) {
    on<LoadAttendancesEvent>(_onLoadAttendances);
    on<CheckInEvent>(_onCheckIn);
    on<CheckOutEvent>(_onCheckOut);
  }

  /// ទាញទិន្នន័យ Attendance ទាំងអស់ ហើយរកថ្ងៃនេះ
  Future<void> _onLoadAttendances(
    LoadAttendancesEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    final result = await _apiService.getAttendances();

    result.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (attendances) {
        final todayStr = _todayString();
        AttendanceModel? today;
        try {
          today = attendances.firstWhere((a) => a.date == todayStr);
        } catch (_) {
          today = null;
        }
        emit(AttendanceLoadedState(
          attendances: attendances,
          todayAttendance: today,
        ));
      },
    );
  }

  /// Check-in ហើយ reload list
  Future<void> _onCheckIn(
    CheckInEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    final result = await _apiService.checkIn();

    result.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (attendance) {
        emit(AttendanceOperationSuccessState(
          message: 'Check-in successful! 🟢',
          attendance: attendance,
        ));
        add(LoadAttendancesEvent());
      },
    );
  }

  /// Check-out ហើយ reload list
  Future<void> _onCheckOut(
    CheckOutEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    final result = await _apiService.checkOut();

    result.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (attendance) {
        emit(AttendanceOperationSuccessState(
          message: 'Check-out successful! 🔴',
          attendance: attendance,
        ));
        add(LoadAttendancesEvent());
      },
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
