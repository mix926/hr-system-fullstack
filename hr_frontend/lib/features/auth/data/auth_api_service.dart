// Location: lib/features/auth/data/auth_api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import '../../employee/data/models/employee_model.dart';

class AuthApiService {
  final Dio _dio;
  
  // ខ្មែរ: ទទួលយក Dio ពី GetIt Service Locator
  AuthApiService(this._dio);

  Future<Result<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      
      // ខ្មែរ: រក្សាទុក Token និង Role ពេល Login ជោគជ័យ
      final prefs = await SharedPreferences.getInstance();
      if (response.data['access_token'] != null) {
        await prefs.setString('token', response.data['access_token']);
      }
      if (response.data['user'] != null && response.data['user']['role'] != null) {
        await prefs.setString('role', response.data['user']['role']);
      }
      
      return Result.success(response.data);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Login failed',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<Employee>> registerEmployee(Employee employee) async {
    try {
      final response = await _dio.post(
        AppConstants.employeesEndpoint, 
        data: employee.toJson(),
      );
      return Result.success(Employee.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Registration failed',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}