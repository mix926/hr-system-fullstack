// lib/features/reports/data/reports_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';

class ReportsApiService {
  final Dio _dio;
  ReportsApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  Future<Result<Map<String, dynamic>>> getHeadcountReport() async {
    try {
      final r = await _dio.get(AppConstants.reportHeadcountEndpoint);
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load headcount report')));
    }
  }

  Future<Result<Map<String, dynamic>>> getTurnoverReport(int year) async {
    try {
      final r = await _dio.get(AppConstants.reportTurnoverEndpoint,
          queryParameters: {'year': year});
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load turnover report')));
    }
  }

  Future<Result<Map<String, dynamic>>> getAttendanceReport({
    required String startDate, required String endDate, String? employeeId,
  }) async {
    try {
      final r = await _dio.get(AppConstants.reportAttendanceEndpoint, queryParameters: {
        'start_date': startDate, 'end_date': endDate,
        if (employeeId != null) 'employee_id': employeeId,
      });
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load attendance report')));
    }
  }

  Future<Result<Map<String, dynamic>>> getPayrollReport(String monthYear) async {
    try {
      final r = await _dio.get(AppConstants.reportPayrollEndpoint,
          queryParameters: {'month_year': monthYear});
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load payroll report')));
    }
  }

  Future<Result<Map<String, dynamic>>> getLeaveReport(int year) async {
    try {
      final r = await _dio.get(AppConstants.reportLeaveEndpoint,
          queryParameters: {'year': year});
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load leave report')));
    }
  }

  Future<Result<Map<String, dynamic>>> getCustomReport(String entity) async {
    try {
      final r = await _dio.get(AppConstants.reportCustomEndpoint,
          queryParameters: {'entity': entity, 'format': 'json'});
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load custom report')));
    }
  }

  /// Returns a URL the app can open to trigger a CSV download.
  String getExportUrl(String reportType, {Map<String, String>? params}) {
    final base = AppConstants.baseUrl;
    String path;
    switch (reportType) {
      case 'headcount':  path = AppConstants.reportHeadcountExportEndpoint; break;
      case 'attendance': path = AppConstants.reportAttendanceExportEndpoint; break;
      case 'payroll':    path = AppConstants.reportPayrollExportEndpoint;    break;
      default:           path = AppConstants.reportCustomEndpoint;
    }
    if (params == null || params.isEmpty) return '$base$path';
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$base$path?$query';
  }
}
