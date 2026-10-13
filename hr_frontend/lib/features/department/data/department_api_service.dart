// Location: lib/features/department/data/department_api_service.dart
import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import 'models/department_model.dart';

class DepartmentApiService {
  final Dio _dio;

  DepartmentApiService(this._dio);

  Future<Result<List<DepartmentModel>>> getDepartments() async {
    try {
      final response = await _dio.get('/api/v1/departments/');
      final List<dynamic> data = response.data;
      return Result.success(
          data.map((json) => DepartmentModel.fromJson(json)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to load departments',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<DepartmentModel>> createDepartment(String name) async {
    try {
      final response =
          await _dio.post('/api/v1/departments/', data: {'name': name});
      return Result.success(DepartmentModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to create department',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<void>> deleteDepartment(String id) async {
    try {
      await _dio.delete('/api/v1/departments/$id');
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to delete department',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
