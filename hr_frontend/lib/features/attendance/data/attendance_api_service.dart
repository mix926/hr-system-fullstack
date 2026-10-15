import 'package:dio/dio.dart';
import '../../../../core/errors/result.dart';
import 'models/attendance_model.dart';

class AttendanceApiService {
  final Dio _dio;

  AttendanceApiService(this._dio);

  Future<Result<AttendanceModel>> checkIn() async {
    try {
      final response = await _dio.post('/api/v1/attendance/check-in');
      return Result.success(AttendanceModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to check-in',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<AttendanceModel>> checkOut() async {
    try {
      final response = await _dio.post('/api/v1/attendance/check-out');
      return Result.success(AttendanceModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to check-out',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<List<AttendanceModel>>> getAttendances() async {
    try {
      final response = await _dio.get('/api/v1/attendance/');
      final List<dynamic> data = response.data;
      return Result.success(data.map((json) => AttendanceModel.fromJson(json)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to load attendances',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}