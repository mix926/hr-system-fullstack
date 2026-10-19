// lib/features/performance/data/performance_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import 'models/performance_model.dart';

class PerformanceApiService {
  final Dio _dio;

  PerformanceApiService(this._dio);

  /// Safely extract the error detail from a DioException response.
  String _extractDetail(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString() ?? fallback;
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return fallback;
  }

  /// Get all performance reviews (admin/manager) or own reviews (staff)
  Future<Result<List<PerformanceReview>>> getReviews() async {
    try {
      final response = await _dio.get('/api/v1/performance/');
      final List<dynamic> data = response.data;
      return Result.success(
        data.map((json) => PerformanceReview.fromJson(json)).toList(),
      );
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to load performance reviews'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get reviews for a specific employee
  Future<Result<List<PerformanceReview>>> getReviewsByEmployee(String employeeId) async {
    try {
      final response = await _dio.get('/api/v1/performance/employee/$employeeId');
      final List<dynamic> data = response.data;
      return Result.success(
        data.map((json) => PerformanceReview.fromJson(json)).toList(),
      );
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to load employee reviews'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Create a new performance review (admin/manager only)
  Future<Result<PerformanceReview>> createReview(PerformanceReview review) async {
    try {
      final response = await _dio.post('/api/v1/performance/', data: review.toJson());
      return Result.success(PerformanceReview.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to create performance review'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Update an existing review (admin/manager only)
  Future<Result<PerformanceReview>> updateReview(
      String reviewId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/api/v1/performance/$reviewId', data: updates);
      return Result.success(PerformanceReview.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to update performance review'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Delete a review (admin only)
  Future<Result<void>> deleteReview(String reviewId) async {
    try {
      await _dio.delete('/api/v1/performance/$reviewId');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to delete performance review'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
