import 'package:dio/dio.dart';
import '../../../../core/errors/result.dart';
import 'models/payroll_model.dart';

class PayrollApiService {
  final Dio _dio;

  PayrollApiService(this._dio);

  Future<Result<List<PayrollModel>>> getPayrolls() async {
    try {
      final response = await _dio.get('/api/v1/payroll/');
      final List<dynamic> data = response.data;
      return Result.success(data.map((json) => PayrollModel.fromJson(json)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to load payrolls',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Future<Result<PayrollModel>> createPayroll(PayrollModel payroll) async {
    try {
      final response = await _dio.post('/api/v1/payroll/', data: payroll.toJson());
      return Result.success(PayrollModel.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to process payroll',
      ));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}