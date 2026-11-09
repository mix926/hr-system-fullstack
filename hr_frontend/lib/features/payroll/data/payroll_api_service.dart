// lib/features/payroll/data/payroll_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import 'models/payroll_model.dart';

class PayrollApiService {
  final Dio _dio;

  PayrollApiService(this._dio);

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

  /// Get all payrolls (admin/manager) or own payrolls (staff)
  Future<Result<List<PayrollModel>>> getPayrolls() async {
    try {
      final response = await _dio.get('/api/v1/payroll/');
      final List<dynamic> data = response.data;
      return Result.success(
        data.map((json) => PayrollModel.fromJson(json)).toList(),
      );
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to load payrolls'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get a single payroll by id
  Future<Result<PayrollModel>> getPayrollById(int id) async {
    try {
      final response = await _dio.get('/api/v1/payroll/$id');
      return Result.success(PayrollModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Payroll record not found'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Create a new payroll record (admin only)
  Future<Result<PayrollModel>> createPayroll(PayrollModel payroll) async {
    try {
      final response = await _dio.post('/api/v1/payroll/', data: payroll.toJson());
      return Result.success(PayrollModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to create payroll'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Update salary fields of a payroll record (admin only)
  Future<Result<PayrollModel>> updatePayroll(
    int id, {
    double? baseSalary,
    double? bonus,
    double? deductions,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (baseSalary != null) body['base_salary'] = baseSalary;
      if (bonus != null) body['bonus'] = bonus;
      if (deductions != null) body['deductions'] = deductions;

      final response = await _dio.patch('/api/v1/payroll/$id', data: body);
      return Result.success(PayrollModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to update payroll'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Update payroll status (admin only)
  Future<Result<PayrollModel>> updatePayrollStatus(int id, String status) async {
    try {
      final response = await _dio.patch(
        '/api/v1/payroll/$id/status',
        data: {'status': status},
      );
      return Result.success(PayrollModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to update payroll status'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Delete a payroll record (admin only)
  Future<Result<void>> deletePayroll(int id) async {
    try {
      await _dio.delete('/api/v1/payroll/$id');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to delete payroll'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// Get payroll summary statistics (admin/manager only)
  Future<Result<Map<String, dynamic>>> getPayrollStats() async {
    try {
      final response = await _dio.get('/api/v1/payroll/stats/summary');
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: _extractDetail(e, 'Failed to load payroll statistics'),
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
