// lib/features/admin/presentation/bloc/admin_bloc.dart
//
// AdminBloc — drives the Admin & Security feature screens.
//
// Events handled:
//   Audit logs  : LoadAuditLogs, LoadEntityAuditTrail
//   Companies   : LoadCompanies, CreateCompany, UpdateCompany, DeleteCompany
//   Branches    : LoadBranches, CreateBranch, UpdateBranch, DeleteBranch
//   Stats       : LoadSystemStats

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/admin_api_service.dart';
import '../../data/models/admin_models.dart';

// ─── Events ────────────────────────────────────────────────────

abstract class AdminEvent {}

// -- Audit logs
class LoadAuditLogsEvent extends AdminEvent {
  final String? actorId;
  final String? entityType;
  final String? action;
  final String? dateFrom;
  final String? dateTo;
  final int limit;
  final int offset;

  LoadAuditLogsEvent({
    this.actorId,
    this.entityType,
    this.action,
    this.dateFrom,
    this.dateTo,
    this.limit = 100,
    this.offset = 0,
  });
}

class LoadEntityAuditTrailEvent extends AdminEvent {
  final String entityType;
  final String entityId;
  LoadEntityAuditTrailEvent(this.entityType, this.entityId);
}

// -- Companies
class LoadCompaniesEvent extends AdminEvent {
  final bool activeOnly;
  LoadCompaniesEvent({this.activeOnly = false});
}

class CreateCompanyEvent extends AdminEvent {
  final Company company;
  CreateCompanyEvent(this.company);
}

class UpdateCompanyEvent extends AdminEvent {
  final String id;
  final Map<String, dynamic> updates;
  UpdateCompanyEvent(this.id, this.updates);
}

class DeleteCompanyEvent extends AdminEvent {
  final String id;
  DeleteCompanyEvent(this.id);
}

// -- Branches
class LoadBranchesEvent extends AdminEvent {
  final String companyId;
  final bool activeOnly;
  LoadBranchesEvent(this.companyId, {this.activeOnly = false});
}

class CreateBranchEvent extends AdminEvent {
  final Branch branch;
  CreateBranchEvent(this.branch);
}

class UpdateBranchEvent extends AdminEvent {
  final String id;
  final Map<String, dynamic> updates;
  UpdateBranchEvent(this.id, this.updates);
}

class DeleteBranchEvent extends AdminEvent {
  final String id;
  DeleteBranchEvent(this.id);
}

// -- System stats
class LoadSystemStatsEvent extends AdminEvent {}

// ─── States ────────────────────────────────────────────────────

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

// Audit logs
class AuditLogsLoaded extends AdminState {
  final List<AuditLog> logs;
  AuditLogsLoaded(this.logs);
}

class EntityAuditTrailLoaded extends AdminState {
  final List<AuditLog> trail;
  final String entityType;
  final String entityId;
  EntityAuditTrailLoaded(this.trail, this.entityType, this.entityId);
}

// Companies
class CompaniesLoaded extends AdminState {
  final List<Company> companies;
  CompaniesLoaded(this.companies);
}

class CompanyCreated extends AdminState {
  final Company company;
  CompanyCreated(this.company);
}

class CompanyUpdated extends AdminState {
  final Company company;
  CompanyUpdated(this.company);
}

class CompanyDeleted extends AdminState {
  final String id;
  CompanyDeleted(this.id);
}

// Branches
class BranchesLoaded extends AdminState {
  final List<Branch> branches;
  final String companyId;
  BranchesLoaded(this.branches, this.companyId);
}

class BranchCreated extends AdminState {
  final Branch branch;
  BranchCreated(this.branch);
}

class BranchUpdated extends AdminState {
  final Branch branch;
  BranchUpdated(this.branch);
}

class BranchDeleted extends AdminState {
  final String id;
  BranchDeleted(this.id);
}

// System stats
class SystemStatsLoaded extends AdminState {
  final SystemStats stats;
  SystemStatsLoaded(this.stats);
}

// Error
class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}

// ─── BLoC ──────────────────────────────────────────────────────

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminApiService _api;

  AdminBloc(this._api) : super(AdminInitial()) {
    on<LoadAuditLogsEvent>(_onLoadAuditLogs);
    on<LoadEntityAuditTrailEvent>(_onLoadEntityTrail);

    on<LoadCompaniesEvent>(_onLoadCompanies);
    on<CreateCompanyEvent>(_onCreateCompany);
    on<UpdateCompanyEvent>(_onUpdateCompany);
    on<DeleteCompanyEvent>(_onDeleteCompany);

    on<LoadBranchesEvent>(_onLoadBranches);
    on<CreateBranchEvent>(_onCreateBranch);
    on<UpdateBranchEvent>(_onUpdateBranch);
    on<DeleteBranchEvent>(_onDeleteBranch);

    on<LoadSystemStatsEvent>(_onLoadStats);
  }

  // ── Audit logs ────────────────────────────────────────────────

  Future<void> _onLoadAuditLogs(
      LoadAuditLogsEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.getAuditLogs(
      actorId:    e.actorId,
      entityType: e.entityType,
      action:     e.action,
      dateFrom:   e.dateFrom,
      dateTo:     e.dateTo,
      limit:      e.limit,
      offset:     e.offset,
    );
    r.fold(
      (f) => emit(AdminError(f.message)),
      (logs) => emit(AuditLogsLoaded(logs)),
    );
  }

  Future<void> _onLoadEntityTrail(
      LoadEntityAuditTrailEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.getEntityAuditTrail(e.entityType, e.entityId);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (trail) => emit(EntityAuditTrailLoaded(trail, e.entityType, e.entityId)),
    );
  }

  // ── Companies ──────────────────────────────────────────────────

  Future<void> _onLoadCompanies(
      LoadCompaniesEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.getCompanies(activeOnly: e.activeOnly);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (list) => emit(CompaniesLoaded(list)),
    );
  }

  Future<void> _onCreateCompany(
      CreateCompanyEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.createCompany(e.company);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (c) => emit(CompanyCreated(c)),
    );
  }

  Future<void> _onUpdateCompany(
      UpdateCompanyEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.updateCompany(e.id, e.updates);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (c) => emit(CompanyUpdated(c)),
    );
  }

  Future<void> _onDeleteCompany(
      DeleteCompanyEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.deleteCompany(e.id);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (_) => emit(CompanyDeleted(e.id)),
    );
  }

  // ── Branches ───────────────────────────────────────────────────

  Future<void> _onLoadBranches(
      LoadBranchesEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.getBranchesForCompany(e.companyId,
        activeOnly: e.activeOnly);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (list) => emit(BranchesLoaded(list, e.companyId)),
    );
  }

  Future<void> _onCreateBranch(
      CreateBranchEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.createBranch(e.branch);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (b) => emit(BranchCreated(b)),
    );
  }

  Future<void> _onUpdateBranch(
      UpdateBranchEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.updateBranch(e.id, e.updates);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (b) => emit(BranchUpdated(b)),
    );
  }

  Future<void> _onDeleteBranch(
      DeleteBranchEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.deleteBranch(e.id);
    r.fold(
      (f) => emit(AdminError(f.message)),
      (_) => emit(BranchDeleted(e.id)),
    );
  }

  // ── System stats ───────────────────────────────────────────────

  Future<void> _onLoadStats(
      LoadSystemStatsEvent e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final r = await _api.getSystemStats();
    r.fold(
      (f) => emit(AdminError(f.message)),
      (s) => emit(SystemStatsLoaded(s)),
    );
  }
}
