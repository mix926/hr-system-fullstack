// lib/features/reports/presentation/bloc/reports_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/reports_api_service.dart';

// ── Events ────────────────────────────────────────────────────
abstract class ReportsEvent {}
class LoadHeadcountReportEvent  extends ReportsEvent {}
class LoadTurnoverReportEvent   extends ReportsEvent { final int year; LoadTurnoverReportEvent(this.year); }
class LoadAttendanceReportEvent extends ReportsEvent {
  final String startDate, endDate;
  LoadAttendanceReportEvent(this.startDate, this.endDate);
}
class LoadPayrollReportEvent    extends ReportsEvent { final String monthYear; LoadPayrollReportEvent(this.monthYear); }
class LoadLeaveReportEvent      extends ReportsEvent { final int year; LoadLeaveReportEvent(this.year); }
class LoadCustomReportEvent     extends ReportsEvent { final String entity; LoadCustomReportEvent(this.entity); }

// ── States ────────────────────────────────────────────────────
abstract class ReportsState {}
class ReportsInitial extends ReportsState {}
class ReportsLoading  extends ReportsState {}
class ReportLoaded    extends ReportsState {
  final String reportType;
  final Map<String, dynamic> data;
  ReportLoaded(this.reportType, this.data);
}
class ReportsError extends ReportsState { final String message; ReportsError(this.message); }

// ── BLoC ──────────────────────────────────────────────────────
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsApiService _api;

  ReportsBloc(this._api) : super(ReportsInitial()) {
    on<LoadHeadcountReportEvent>(_onHeadcount);
    on<LoadTurnoverReportEvent>(_onTurnover);
    on<LoadAttendanceReportEvent>(_onAttendance);
    on<LoadPayrollReportEvent>(_onPayroll);
    on<LoadLeaveReportEvent>(_onLeave);
    on<LoadCustomReportEvent>(_onCustom);
  }

  Future<void> _onHeadcount(LoadHeadcountReportEvent e, Emitter emit) async {
    emit(ReportsLoading());
    final r = await _api.getHeadcountReport();
    r.fold((f) => emit(ReportsError(f.message)), (d) => emit(ReportLoaded('headcount', d)));
  }

  Future<void> _onTurnover(LoadTurnoverReportEvent e, Emitter emit) async {
    emit(ReportsLoading());
    final r = await _api.getTurnoverReport(e.year);
    r.fold((f) => emit(ReportsError(f.message)), (d) => emit(ReportLoaded('turnover', d)));
  }

  Future<void> _onAttendance(LoadAttendanceReportEvent e, Emitter emit) async {
    emit(ReportsLoading());
    final r = await _api.getAttendanceReport(startDate: e.startDate, endDate: e.endDate);
    r.fold((f) => emit(ReportsError(f.message)), (d) => emit(ReportLoaded('attendance', d)));
  }

  Future<void> _onPayroll(LoadPayrollReportEvent e, Emitter emit) async {
    emit(ReportsLoading());
    final r = await _api.getPayrollReport(e.monthYear);
    r.fold((f) => emit(ReportsError(f.message)), (d) => emit(ReportLoaded('payroll', d)));
  }

  Future<void> _onLeave(LoadLeaveReportEvent e, Emitter emit) async {
    emit(ReportsLoading());
    final r = await _api.getLeaveReport(e.year);
    r.fold((f) => emit(ReportsError(f.message)), (d) => emit(ReportLoaded('leave', d)));
  }

  Future<void> _onCustom(LoadCustomReportEvent e, Emitter emit) async {
    emit(ReportsLoading());
    final r = await _api.getCustomReport(e.entity);
    r.fold((f) => emit(ReportsError(f.message)), (d) => emit(ReportLoaded(e.entity, d)));
  }
}
