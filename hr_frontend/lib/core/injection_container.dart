// Location: lib/core/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../features/auth/data/auth_api_service.dart';
import '../features/employee/data/employee_api_service.dart';
import 'network/api_interceptor.dart';
import 'utils/constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<Dio>(() {
    // ខ្មែរ: ប្រើ AppConstants.baseUrl ជា Single Source of Truth
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    dio.interceptors.add(AuthInterceptor());
    return dio;
  });

  sl.registerLazySingleton<AuthApiService>(() => AuthApiService(sl()));
  sl.registerLazySingleton<EmployeeApiService>(() => EmployeeApiService(sl()));
}
