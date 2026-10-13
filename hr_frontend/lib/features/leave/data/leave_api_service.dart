// Location: lib/features/leave/data/leave_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
// ខ្មែរ: ជួសជុល — ទីតាំងត្រឹមត្រូវ models/ ស្ថិតក្នុង data/ folder ដូចគ្នា
import 'models/leave_model.dart';

class LeaveApiService {
  final Dio _dio;

  LeaveApiService(this._dio);

  /// ខ្មែរ: ទាញយកបញ្ជីសំណើសុំច្បាប់
  Future<Result<List<LeaveModel>>> getLeaves() async {
    try {
      final response = await _dio.get('/api/v1/leaves/');
      final List<dynamic> data = response.data;
      return Result.success(data.map((json) => LeaveModel.fromJson(json)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to load leave requests',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// ខ្មែរ: បង្កើតសំណើសុំច្បាប់ថ្មី
  Future<Result<LeaveModel>> createLeave(LeaveModel leave) async {
    try {
      final response = await _dio.post('/api/v1/leaves/', data: leave.toJson());
      return Result.success(LeaveModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to create leave request',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// ខ្មែរ: ទាញយករាប់ចំនួនច្បាប់តាម Status
  Future<Result<Map<String, int>>> getLeaveStats() async {
    try {
      final response = await _dio.get('/api/v1/leaves/stats');
      final data = response.data as Map<String, dynamic>;
      return Result.success({
        'total':    (data['total']    as num).toInt(),
        'pending':  (data['pending']  as num).toInt(),
        'approved': (data['approved'] as num).toInt(),
        'rejected': (data['rejected'] as num).toInt(),
      });
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to load leave stats',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  /// ខ្មែរ: ADMIN/MANAGER អនុម័ត ឬ បដិសេធ សំណើសុំច្បាប់
  Future<Result<LeaveModel>> updateLeaveStatus(String leaveId, String status) async {
    try {
      final response = await _dio.patch(
        '/api/v1/leaves/$leaveId/status',
        data: {'status': status},
      );
      return Result.success(LeaveModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to update leave status',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}