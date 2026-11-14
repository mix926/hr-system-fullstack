// lib/features/employee/data/employee_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/employee_model.dart';

class EmployeeApiService {
  final Dio _dio;
  EmployeeApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  // ── Core CRUD ─────────────────────────────────────────────────

  Future<Result<List<Employee>>> getEmployees() async {
    try {
      final r = await _dio.get(AppConstants.employeesEndpoint);
      return Result.success((r.data as List).map((j) => Employee.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load employees')));
    }
  }

  Future<Result<Employee>> getEmployeeById(String id) async {
    try {
      final r = await _dio.get('${AppConstants.employeesEndpoint}/$id');
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Employee not found')));
    }
  }

  Future<Result<Employee>> createEmployee(Employee employee) async {
    try {
      final r = await _dio.post(AppConstants.employeesEndpoint, data: employee.toJson());
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create employee')));
    }
  }

  Future<Result<Employee>> updateEmployee(String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch('${AppConstants.employeesEndpoint}/$id', data: updates);
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update employee')));
    }
  }

  Future<Result<void>> deleteEmployee(String id) async {
    try {
      await _dio.delete('${AppConstants.employeesEndpoint}/$id');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete employee')));
    }
  }

  Future<Result<List<Employee>>> searchEmployees(String q) async {
    try {
      final r = await _dio.get(AppConstants.employeeSearchEndpoint, queryParameters: {'q': q});
      return Result.success((r.data as List).map((j) => Employee.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Search failed')));
    }
  }

  Future<Result<Map<String, dynamic>>> getStats() async {
    try {
      final r = await _dio.get(AppConstants.employeeStatsEndpoint);
      return Result.success(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load stats')));
    }
  }

  // ── Extended Profile ──────────────────────────────────────────

  Future<Result<Employee>> getProfile(String id) async {
    try {
      final r = await _dio.get(AppConstants.employeeProfileEndpoint(id));
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load profile')));
    }
  }

  Future<Result<Employee>> updateProfile(String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch(AppConstants.employeeProfileEndpoint(id), data: updates);
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update profile')));
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────

  Future<Result<Employee>> updateStatus(String id, String status, {String? exitDate}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (exitDate != null) body['exit_date'] = exitDate;
      final r = await _dio.patch(AppConstants.employeeStatusEndpoint(id), data: body);
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update status')));
    }
  }

  // ── Hierarchy ─────────────────────────────────────────────────

  Future<Result<Employee>> setManager(String id, String? managerId) async {
    try {
      final r = await _dio.patch(AppConstants.employeeManagerEndpoint(id), data: {'manager_id': managerId});
      return Result.success(Employee.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to set manager')));
    }
  }

  Future<Result<List<Employee>>> getDirectReports(String id) async {
    try {
      final r = await _dio.get(AppConstants.employeeDirectReportsEndpoint(id));
      return Result.success((r.data as List).map((j) => Employee.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load direct reports')));
    }
  }

  Future<Result<List<OrgNode>>> getOrgChart(String id) async {
    try {
      final r = await _dio.get(AppConstants.employeeOrgChartEndpoint(id));
      final chain = (r.data['chain'] as List);
      return Result.success(chain.map((j) => OrgNode.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load org chart')));
    }
  }

  // ── Documents ─────────────────────────────────────────────────

  Future<Result<List<EmployeeDocument>>> getDocuments(String employeeId) async {
    try {
      final r = await _dio.get(AppConstants.employeeDocumentsEndpoint(employeeId));
      return Result.success((r.data as List).map((j) => EmployeeDocument.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load documents')));
    }
  }

  Future<Result<List<EmployeeDocument>>> getExpiringDocuments({int days = 30}) async {
    try {
      final r = await _dio.get(AppConstants.expiringDocsEndpoint, queryParameters: {'days': days});
      return Result.success((r.data as List).map((j) => EmployeeDocument.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load expiring documents')));
    }
  }

  Future<Result<void>> deleteDocument(String docId) async {
    try {
      await _dio.delete(AppConstants.documentEndpoint(docId));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete document')));
    }
  }

  // ── Designations ──────────────────────────────────────────────

  Future<Result<List<Designation>>> getDesignations({String? departmentId}) async {
    try {
      final r = await _dio.get(
        AppConstants.designationsEndpoint,
        queryParameters: departmentId != null ? {'department_id': departmentId} : null,
      );
      return Result.success((r.data as List).map((j) => Designation.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load designations')));
    }
  }

  Future<Result<Designation>> createDesignation(Designation d) async {
    try {
      final r = await _dio.post(AppConstants.designationsEndpoint, data: d.toJson());
      return Result.success(Designation.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create designation')));
    }
  }

  Future<Result<void>> deleteDesignation(String id) async {
    try {
      await _dio.delete(AppConstants.designationEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete designation')));
    }
  }
}
