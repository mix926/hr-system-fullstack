// lib/features/payroll/data/payroll_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/payroll_model.dart';

class PayrollApiService {
  final Dio _dio;
  PayrollApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  // ── Core payroll ──────────────────────────────────────────────

  Future<Result<List<PayrollModel>>> getPayrolls() async {
    try {
      final r = await _dio.get(AppConstants.payrollEndpoint);
      return Result.success((r.data as List).map((j) => PayrollModel.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load payrolls')));
    }
  }

  Future<Result<PayrollModel>> getPayrollById(int id) async {
    try {
      final r = await _dio.get(AppConstants.payrollByIdEndpoint(id));
      return Result.success(PayrollModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Payroll not found')));
    }
  }

  Future<Result<PayrollModel>> createPayroll(PayrollModel p) async {
    try {
      final r = await _dio.post(AppConstants.payrollEndpoint, data: p.toJson());
      return Result.success(PayrollModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create payroll')));
    }
  }

  Future<Result<PayrollModel>> updatePayroll(int id, {double? baseSalary, double? bonus, double? deductions}) async {
    try {
      final body = <String, dynamic>{};
      if (baseSalary  != null) body['base_salary'] = baseSalary;
      if (bonus       != null) body['bonus']       = bonus;
      if (deductions  != null) body['deductions']  = deductions;
      final r = await _dio.patch(AppConstants.payrollByIdEndpoint(id), data: body);
      return Result.success(PayrollModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update payroll')));
    }
  }

  Future<Result<PayrollModel>> updatePayrollStatus(int id, String status) async {
    try {
      final r = await _dio.patch(AppConstants.payrollStatusEndpoint(id), data: {'status': status});
      return Result.success(PayrollModel.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update status')));
    }
  }

  Future<Result<void>> deletePayroll(int id) async {
    try {
      await _dio.delete(AppConstants.payrollByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete payroll')));
    }
  }

  Future<Result<Map<String, dynamic>>> getPayrollStats() async {
    try {
      final r = await _dio.get(AppConstants.payrollStatsEndpoint);
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load stats')));
    }
  }

  // ── Salary structures ─────────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getSalaryStructures() async {
    try {
      final r = await _dio.get(AppConstants.payrollStructuresEndpoint);
      return Result.success((r.data as List).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load salary structures')));
    }
  }

  Future<Result<Map<String, dynamic>>> createSalaryStructure(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post(AppConstants.payrollStructuresEndpoint, data: data);
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create salary structure')));
    }
  }

  Future<Result<void>> deleteSalaryStructure(String id) async {
    try {
      await _dio.delete(AppConstants.payrollStructureEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete structure')));
    }
  }

  // ── Payslip detail ────────────────────────────────────────────

  Future<Result<Map<String, dynamic>>> getPayslipDetail(int payrollId) async {
    try {
      final r = await _dio.get(AppConstants.payslipEndpoint(payrollId));
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load payslip')));
    }
  }

  /// Returns the PDF download URL — the UI opens this in a browser/viewer.
  String getPayslipPdfUrl(int payrollId) =>
      '${AppConstants.baseUrl}${AppConstants.payslipPdfEndpoint(payrollId)}';

  /// Returns the bank file download URL.
  String getBankFileUrl(String monthYear) =>
      '${AppConstants.baseUrl}${AppConstants.payrollBankFileEndpoint}?month_year=$monthYear';

  // ── Generate payroll from structure ───────────────────────────

  Future<Result<Map<String, dynamic>>> generatePayroll({
    required String employeeId,
    required String monthYear,
    required String salaryStructureId,
    double bonus = 0,
    double overtimePay = 0,
  }) async {
    try {
      final r = await _dio.post(AppConstants.payrollGenerateEndpoint, data: {
        'employee_id':        employeeId,
        'month_year':         monthYear,
        'salary_structure_id': salaryStructureId,
        'bonus':              bonus,
        'overtime_pay':       overtimePay,
      });
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to generate payroll')));
    }
  }

  // ── Gratuity ──────────────────────────────────────────────────

  Future<Result<Map<String, dynamic>>> getGratuity(String employeeId) async {
    try {
      final r = await _dio.get(AppConstants.gratuityEndpoint(employeeId));
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to calculate gratuity')));
    }
  }
}
