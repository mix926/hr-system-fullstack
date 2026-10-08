// Location: lib/features/auth/data/auth_api_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ខ្មែរ: ទាញយក Result និង Failure
import '../../../core/errors/result.dart';
// ខ្មែរ: ទាញយក Employee Model
import '../../employee/data/models/employee_model.dart';

class AuthApiService {
  final Dio _dio;
  
  // ខ្មែរ: ទទួលយក Dio ពី GetIt Service Locator
  AuthApiService(this._dio);

  Future<Result<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/login',
        data: {'email': email, 'password': password},
      );
      
      // ខ្មែរ: រក្សាទុក Token និង Role ពេល Login ជោគជ័យ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.data['access_token']);
      await prefs.setString('role', response.data['user']['role']);
      
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
      final response = await _dio.post('/api/v1/employees/', data: employee.toJson());
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