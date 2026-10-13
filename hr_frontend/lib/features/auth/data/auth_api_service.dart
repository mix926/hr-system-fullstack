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

      final prefs = await SharedPreferences.getInstance();

      // ខ្មែរ: ជួសជុល — រក្សាទុក Token ដោយប្រើ 'jwt_token' (ត្រូវគ្នាទៅ AppConstants.tokenKey)
      if (response.data['access_token'] != null) {
        await prefs.setString(AppConstants.tokenKey, response.data['access_token']);
      }

      // ខ្មែរ: ជួសជុល — រក្សាទុកព័ត៌មានអ្នកប្រើប្រាស់ ដើម្បីឱ្យ Profile Page អាចបង្ហាញបាន
      final user = response.data['user'];
      if (user != null) {
        await prefs.setString('role',       user['role']       ?? '');
        await prefs.setString('email',      user['email']      ?? '');
        await prefs.setString('first_name', user['first_name'] ?? '');
        await prefs.setString('last_name',  user['last_name']  ?? '');
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
