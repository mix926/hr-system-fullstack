// lib/features/performance/data/performance_enhanced_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/performance_enhanced_models.dart';

class PerformanceEnhancedApiService {
  final Dio _dio;
  PerformanceEnhancedApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  // ── Goals ─────────────────────────────────────────────────────

  Future<Result<List<PerformanceGoal>>> getGoals({
    String? employeeId, String? period, String? goalType, String? status,
  }) async {
    try {
      final r = await _dio.get(AppConstants.goalsEndpoint, queryParameters: {
        if (employeeId != null) 'employee_id': employeeId,
        if (period     != null) 'period':      period,
        if (goalType   != null) 'goal_type':   goalType,
        if (status     != null) 'status_filter': status,
      });
      return Result.success((r.data as List).map((j) => PerformanceGoal.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load goals')));
    }
  }

  Future<Result<PerformanceGoal>> createGoal(PerformanceGoal goal) async {
    try {
      final r = await _dio.post(AppConstants.goalsEndpoint, data: goal.toJson());
      return Result.success(PerformanceGoal.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create goal')));
    }
  }

  Future<Result<PerformanceGoal>> updateGoalProgress(String id, double currentValue, {String? status}) async {
    try {
      final r = await _dio.patch(AppConstants.goalProgressEndpoint(id), data: {
        'current_value': currentValue,
        if (status != null) 'status': status,
      });
      return Result.success(PerformanceGoal.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update progress')));
    }
  }

  Future<Result<void>> deleteGoal(String id) async {
    try {
      await _dio.delete(AppConstants.goalByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete goal')));
    }
  }

  // ── 360° Reviews ─────────────────────────────────────────────

  Future<Result<List<Review360>>> get360Reviews({String? employeeId, String? period}) async {
    try {
      final r = await _dio.get(AppConstants.reviews360Endpoint, queryParameters: {
        if (employeeId != null) 'employee_id':   employeeId,
        if (period     != null) 'review_period': period,
      });
      return Result.success((r.data as List).map((j) => Review360.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load 360 reviews')));
    }
  }

  Future<Result<Review360>> create360Review(Review360 review) async {
    try {
      final r = await _dio.post(AppConstants.reviews360Endpoint, data: review.toJson());
      return Result.success(Review360.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create review')));
    }
  }

  Future<Result<void>> delete360Review(String id) async {
    try {
      await _dio.delete(AppConstants.review360ByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete review')));
    }
  }

  // ── PIPs ──────────────────────────────────────────────────────

  Future<Result<List<PIP>>> getPIPs({String? employeeId, String? status}) async {
    try {
      final r = await _dio.get(AppConstants.pipsEndpoint, queryParameters: {
        if (employeeId != null) 'employee_id':    employeeId,
        if (status     != null) 'status_filter':  status,
      });
      return Result.success((r.data as List).map((j) => PIP.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load PIPs')));
    }
  }

  Future<Result<PIP>> getPIPById(String id) async {
    try {
      final r = await _dio.get(AppConstants.pipByIdEndpoint(id));
      return Result.success(PIP.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'PIP not found')));
    }
  }

  Future<Result<PIP>> createPIP(PIP pip) async {
    try {
      final r = await _dio.post(AppConstants.pipsEndpoint, data: pip.toJson());
      return Result.success(PIP.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create PIP')));
    }
  }

  Future<Result<PIP>> updatePIP(String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch(AppConstants.pipByIdEndpoint(id), data: updates);
      return Result.success(PIP.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update PIP')));
    }
  }

  Future<Result<PIPMilestone>> addMilestone(String pipId, PIPMilestone m) async {
    try {
      final r = await _dio.post(AppConstants.pipMilestonesEndpoint(pipId), data: m.toJson());
      return Result.success(PIPMilestone.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to add milestone')));
    }
  }

  Future<Result<PIPMilestone>> updateMilestone(
      String pipId, String milestoneId, bool met, {String? notes}) async {
    try {
      final r = await _dio.patch(AppConstants.pipMilestoneEndpoint(pipId, milestoneId),
          data: {'met': met, if (notes != null) 'notes': notes});
      return Result.success(PIPMilestone.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update milestone')));
    }
  }
}
