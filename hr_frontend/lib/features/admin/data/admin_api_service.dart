// lib/features/admin/data/admin_api_service.dart
//
// AdminApiService — connects the Flutter frontend to every endpoint
// defined in hr-backend/app/api/admin.py:
//
//   Audit Logs  : GET /admin/audit-logs, GET export, GET entity trail
//   Companies   : GET / POST / PATCH / DELETE /admin/companies
//   Branches    : GET /admin/companies/{id}/branches, POST/PATCH/DELETE /admin/branches
//   Stats       : GET /admin/stats

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/admin_models.dart';

class AdminApiService {
  final Dio _dio;
  AdminApiService(this._dio);

  // ── Internal helper ───────────────────────────────────────────

  String _detail(DioException e, String fallback) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fallback;
    if (d is String && d.isNotEmpty) return d;
    return fallback;
  }

  // ─── Audit Logs ───────────────────────────────────────────────

  /// Fetch audit logs with optional filters.
  /// All params map 1-to-1 to backend query params.
  Future<Result<List<AuditLog>>> getAuditLogs({
    String? actorId,
    String? entityType,
    String? action,
    String? dateFrom,   // "YYYY-MM-DD"
    String? dateTo,     // "YYYY-MM-DD"
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final r = await _dio.get(
        AppConstants.auditLogsEndpoint,
        queryParameters: {
          'limit':  limit,
          'offset': offset,
          if (actorId    != null) 'actor_id':    actorId,
          if (entityType != null) 'entity_type': entityType,
          if (action     != null) 'action':      action,
          if (dateFrom   != null) 'date_from':   dateFrom,
          if (dateTo     != null) 'date_to':     dateTo,
        },
      );
      return Result.success(
          (r.data as List).map((j) => AuditLog.fromJson(j as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load audit logs')));
    }
  }

  /// Get the complete audit trail for one specific record.
  Future<Result<List<AuditLog>>> getEntityAuditTrail(
      String entityType, String entityId) async {
    try {
      final r = await _dio.get(AppConstants.auditTrailEndpoint(entityType, entityId));
      return Result.success(
          (r.data as List).map((j) => AuditLog.fromJson(j as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Result.failure(
          ServerFailure(message: _detail(e, 'Failed to load audit trail')));
    }
  }

  /// Returns a URL you can open in a browser/webview to download the CSV.
  String getAuditLogsExportUrl({
    String? entityType,
    String? action,
    String? dateFrom,
    String? dateTo,
  }) {
    final params = <String, String>{};
    if (entityType != null) params['entity_type'] = entityType;
    if (action     != null) params['action']      = action;
    if (dateFrom   != null) params['date_from']   = dateFrom;
    if (dateTo     != null) params['date_to']     = dateTo;

    final base = AppConstants.baseUrl + AppConstants.auditLogsExportEndpoint;
    if (params.isEmpty) return base;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$base?$query';
  }

  // ─── Companies ────────────────────────────────────────────────

  Future<Result<List<Company>>> getCompanies({bool activeOnly = false}) async {
    try {
      final r = await _dio.get(AppConstants.companiesEndpoint,
          queryParameters: {'active_only': activeOnly});
      return Result.success(
          (r.data as List).map((j) => Company.fromJson(j as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load companies')));
    }
  }

  Future<Result<Company>> createCompany(Company company) async {
    try {
      final r = await _dio.post(AppConstants.companiesEndpoint, data: company.toJson());
      return Result.success(Company.fromJson(r.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create company')));
    }
  }

  Future<Result<Company>> updateCompany(
      String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch(AppConstants.companyByIdEndpoint(id), data: updates);
      return Result.success(Company.fromJson(r.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update company')));
    }
  }

  Future<Result<void>> deleteCompany(String id) async {
    try {
      await _dio.delete(AppConstants.companyByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to deactivate company')));
    }
  }

  // ─── Branches ─────────────────────────────────────────────────

  Future<Result<List<Branch>>> getBranchesForCompany(
      String companyId, {bool activeOnly = false}) async {
    try {
      final r = await _dio.get(
        AppConstants.companyBranchesEndpoint(companyId),
        queryParameters: {'active_only': activeOnly},
      );
      return Result.success(
          (r.data as List).map((j) => Branch.fromJson(j as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load branches')));
    }
  }

  Future<Result<Branch>> createBranch(Branch branch) async {
    try {
      final r = await _dio.post(AppConstants.branchesEndpoint, data: branch.toJson());
      return Result.success(Branch.fromJson(r.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create branch')));
    }
  }

  Future<Result<Branch>> updateBranch(
      String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch(AppConstants.branchByIdEndpoint(id), data: updates);
      return Result.success(Branch.fromJson(r.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update branch')));
    }
  }

  Future<Result<void>> deleteBranch(String id) async {
    try {
      await _dio.delete(AppConstants.branchByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to deactivate branch')));
    }
  }

  // ─── System Stats ──────────────────────────────────────────────

  /// Dashboard stats (ADMIN + MANAGER).
  Future<Result<SystemStats>> getSystemStats() async {
    try {
      final r = await _dio.get(AppConstants.adminStatsEndpoint);
      return Result.success(SystemStats.fromJson(r.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load system stats')));
    }
  }
}
