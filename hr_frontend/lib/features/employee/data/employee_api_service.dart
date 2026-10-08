// Location: lib/features/auth/employee/data/employee_api_service.dart
import 'package:dio/dio.dart';

import '../../../core/errors/result.dart';
import 'models/employee_model.dart';

class EmployeeApiService {
  final Dio _dio;

  // ខ្មែរ: ទទួលយក Dio ពី GetIt Service Locator
  EmployeeApiService(this._dio);

  Future<Result<List<Employee>>> getEmployees() async {
    try {
      // ខ្មែរ: Interceptor ដោះស្រាយ Token ដោយស្វ័យប្រវត្តិ
      final response = await _dio.get('/api/v1/employees/');
      final List<dynamic> data = response.data;
      return Result.success(data.map((json) => Employee.fromJson(json)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to load employees',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<Employee>> createEmployee(Employee employee) async {
    try {
      final response = await _dio.post('/api/v1/employees/', data: employee.toJson());
      return Result.success(Employee.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to create employee',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteEmployee(String id) async {
    try {
      await _dio.delete('/api/v1/employees/$id');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to delete employee',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
