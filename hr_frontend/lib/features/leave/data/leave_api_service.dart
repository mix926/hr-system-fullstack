// lib/features/leave/data/leave_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/leave_model.dart';

class LeaveApiService {
  final Dio _dio;
  LeaveApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  // ── Core leave requests ───────────────────────────────────────

  Future<Result<List<LeaveModel>>> getLeaves() async {
    try {
      final r = await _dio.get(AppConstants.leavesEndpoint);
      return Result.success((r.data as List).map((j) => LeaveModel.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load leave requests')));
    }
  }

  Future<Result<LeaveModel>> createLeave(LeaveModel leave) async {
    try {
      final r = await _dio.post(AppConstants.leavesEndpoint, data: leave.toJson());
      return Result.success(LeaveModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create leave request')));
    }
  }

  Future<Result<Map<String, int>>> getLeaveStats() async {
    try {
      final r = await _dio.get(AppConstants.leaveStatsEndpoint);
      final d = r.data as Map<String, dynamic>;
      return Result.success({
        'total':    (d['total']    as num).toInt(),
        'pending':  (d['pending']  as num).toInt(),
        'approved': (d['approved'] as num).toInt(),
        'rejected': (d['rejected'] as num).toInt(),
      });
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load leave stats')));
    }
  }

  Future<Result<LeaveModel>> updateLeaveStatus(String leaveId, String status) async {
    try {
      final r = await _dio.patch(AppConstants.leaveStatusEndpoint(leaveId), data: {'status': status});
      return Result.success(LeaveModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update leave status')));
    }
  }

  // ── Leave types ───────────────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getLeaveTypes({bool activeOnly = false}) async {
    try {
      final r = await _dio.get(AppConstants.leaveTypesEndpoint,
          queryParameters: activeOnly ? {'active_only': true} : null);
      return Result.success((r.data as List).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load leave types')));
    }
  }

  Future<Result<Map<String, dynamic>>> createLeaveType(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post(AppConstants.leaveTypesEndpoint, data: data);
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create leave type')));
    }
  }

  Future<Result<void>> deleteLeaveType(String id) async {
    try {
      await _dio.delete(AppConstants.leaveTypeEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete leave type')));
    }
  }

  // ── Leave balances ────────────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getLeaveBalances(String employeeId, {int? year}) async {
    try {
      final r = await _dio.get(AppConstants.leaveBalanceByEmployeeEndpoint(employeeId),
          queryParameters: year != null ? {'year': year} : null);
      return Result.success((r.data as List).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load leave balances')));
    }
  }

  // ── Multi-level approval ──────────────────────────────────────

  Future<Result<LeaveModel>> createEnhancedLeave(LeaveModel leave) async {
    try {
      final r = await _dio.post(AppConstants.leaveRequestsEndpoint, data: leave.toJson());
      return Result.success(LeaveModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to submit leave request')));
    }
  }

  Future<Result<LeaveModel>> approveLeave(String leaveId, bool approved, {String? comments}) async {
    try {
      final r = await _dio.patch(AppConstants.leaveApproveEndpoint(leaveId),
          data: {'approved': approved, if (comments != null) 'comments': comments});
      return Result.success(LeaveModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to process approval')));
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getApprovalSteps(String leaveId) async {
    try {
      final r = await _dio.get(AppConstants.leaveApprovalsEndpoint(leaveId));
      return Result.success((r.data as List).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load approval steps')));
    }
  }

  // ── Encashment ────────────────────────────────────────────────

  Future<Result<Map<String, dynamic>>> requestEncashment(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post(AppConstants.leaveEncashmentsEndpoint, data: data);
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to request encashment')));
    }
  }

  Future<Result<List<Map<String, dynamic>>>> getEncashments({String? employeeId}) async {
    try {
      final r = await _dio.get(AppConstants.leaveEncashmentsEndpoint,
          queryParameters: employeeId != null ? {'employee_id': employeeId} : null);
      return Result.success((r.data as List).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load encashments')));
    }
  }
}
