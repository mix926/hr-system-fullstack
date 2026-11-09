// lib/features/payroll/presentation/bloc/payroll_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/payroll_api_service.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  final PayrollApiService _apiService;

  PayrollBloc(this._apiService) : super(PayrollInitialState()) {
    on<LoadPayrollsEvent>(_onLoadPayrolls);
    on<LoadPayrollStatsEvent>(_onLoadStats);
    on<CreatePayrollEvent>(_onCreatePayroll);
    on<UpdatePayrollEvent>(_onUpdatePayroll);
    on<UpdatePayrollStatusEvent>(_onUpdateStatus);
    on<DeletePayrollEvent>(_onDeletePayroll);
  }

  // ── Load plain payroll list (staff view) ──────────────────────
  Future<void> _onLoadPayrolls(
      LoadPayrollsEvent event, Emitter<PayrollState> emit) async {
    emit(PayrollLoadingState());
    final result = await _apiService.getPayrolls();
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (payrolls) => emit(PayrollLoadedState(payrolls)),
    );
  }

  // ── Load payrolls + stats (admin/manager view) ────────────────
  Future<void> _onLoadStats(
      LoadPayrollStatsEvent event, Emitter<PayrollState> emit) async {
    emit(PayrollLoadingState());
    final payrollsResult = await _apiService.getPayrolls();
    final statsResult = await _apiService.getPayrollStats();

    payrollsResult.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (payrolls) {
        statsResult.fold(
          // Stats failed (e.g. STAFF role) — fall back to plain list
          (failure) => emit(PayrollLoadedState(payrolls)),
          (stats) => emit(PayrollStatsLoadedState(payrolls, stats)),
        );
      },
    );
  }

  // ── Create payroll ────────────────────────────────────────────
  Future<void> _onCreatePayroll(
      CreatePayrollEvent event, Emitter<PayrollState> emit) async {
    emit(PayrollLoadingState());
    final result = await _apiService.createPayroll(event.payroll);
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (_) {
        emit(PayrollOperationSuccessState('Payroll created successfully!'));
        add(LoadPayrollStatsEvent());
      },
    );
  }

  // ── Update salary fields ──────────────────────────────────────
  Future<void> _onUpdatePayroll(
      UpdatePayrollEvent event, Emitter<PayrollState> emit) async {
    final result = await _apiService.updatePayroll(
      event.payrollId,
      baseSalary: event.baseSalary,
      bonus: event.bonus,
      deductions: event.deductions,
    );
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (_) {
        emit(PayrollOperationSuccessState('Payroll updated successfully!'));
        add(LoadPayrollStatsEvent());
      },
    );
  }

  // ── Update status ─────────────────────────────────────────────
  Future<void> _onUpdateStatus(
      UpdatePayrollStatusEvent event, Emitter<PayrollState> emit) async {
    final result =
        await _apiService.updatePayrollStatus(event.payrollId, event.status);
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (_) {
        emit(PayrollOperationSuccessState('Status updated to ${event.status}'));
        add(LoadPayrollStatsEvent());
      },
    );
  }

  // ── Delete payroll ────────────────────────────────────────────
  Future<void> _onDeletePayroll(
      DeletePayrollEvent event, Emitter<PayrollState> emit) async {
    final result = await _apiService.deletePayroll(event.payrollId);
    result.fold(
      (failure) => emit(PayrollErrorState(failure.message)),
      (_) {
        emit(PayrollOperationSuccessState('Payroll deleted successfully!'));
        add(LoadPayrollStatsEvent());
      },
    );
  }
}
