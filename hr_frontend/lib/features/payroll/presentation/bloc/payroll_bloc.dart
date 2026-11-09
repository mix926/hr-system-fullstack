// lib/features/payroll/presentation/bloc/payroll_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/payroll_api_service.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  final PayrollApiService _apiService;

  PayrollBloc(this._apiService) : super(PayrollInitialState()) {
    on<LoadPayrollsEvent>(_onLoadPayrolls);
    on<CreatePayrollEvent>(_onCreatePayroll);
    on<UpdatePayrollStatusEvent>(_onUpdateStatus);
    on<DeletePayrollEvent>(_onDeletePayroll);
    on<LoadPayrollStatsEvent>(_onLoadStats);
  }

  Future<void> _onLoadPayrolls(
      LoadPayrollsEvent event, Emitter<PayrollState> emit) async {
    emit(PayrollLoadingState());
    final result = await _apiService.getPayrolls();

    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (payrolls) => emit(PayrollLoadedState(payrolls)),
    );
  }

  Future<void> _onCreatePayroll(
      CreatePayrollEvent event, Emitter<PayrollState> emit) async {
    emit(PayrollLoadingState());
    final result = await _apiService.createPayroll(event.payroll);

    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (success) {
        emit(PayrollOperationSuccessState('Payroll created successfully!'));
        add(LoadPayrollsEvent());
      },
    );
  }

  Future<void> _onUpdateStatus(
      UpdatePayrollStatusEvent event, Emitter<PayrollState> emit) async {
    final result = await _apiService.updatePayrollStatus(event.payrollId, event.status);
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (success) {
        emit(PayrollOperationSuccessState(
            'Status updated to ${event.status}'));
        add(LoadPayrollsEvent());
      },
    );
  }

  Future<void> _onDeletePayroll(
      DeletePayrollEvent event, Emitter<PayrollState> emit) async {
    final result = await _apiService.deletePayroll(event.payrollId);
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (success) {
        emit(PayrollOperationSuccessState('Payroll deleted successfully!'));
        add(LoadPayrollsEvent());
      },
    );
  }

  Future<void> _onLoadStats(
      LoadPayrollStatsEvent event, Emitter<PayrollState> emit) async {
    emit(PayrollLoadingState());
    final payrollsResult = await _apiService.getPayrolls();
    final statsResult = await _apiService.getPayrollStats();

    payrollsResult.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (payrolls) {
        statsResult.fold(
          (failure) => emit(PayrollLoadedState(payrolls)),
          (stats) => emit(PayrollStatsLoadedState(payrolls, stats)),
        );
      },
    );
  }
}
