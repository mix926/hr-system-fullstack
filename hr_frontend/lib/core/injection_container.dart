// lib/core/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../features/auth/data/auth_api_service.dart';
import '../features/employee/data/employee_api_service.dart';
import '../features/employee/presentation/bloc/employee_bloc.dart';
import '../features/leave/data/leave_api_service.dart';
import '../features/leave/presentation/bloc/leave_bloc.dart';
import '../features/department/data/department_api_service.dart';
import '../features/attendance/data/attendance_api_service.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';
import 'network/api_interceptor.dart';
import 'utils/constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ខ្មែរ: ចុះឈ្មោះ Dio ជា Single Instance ដែលមាន Base URL និង Auth Interceptor
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    dio.interceptors.add(AuthInterceptor());
    return dio;
  });

  // ── API Services ─────────────────────────────────────────────
  sl.registerLazySingleton<AuthApiService>(() => AuthApiService(sl()));
  sl.registerLazySingleton<EmployeeApiService>(() => EmployeeApiService(sl()));
  sl.registerLazySingleton<LeaveApiService>(() => LeaveApiService(sl()));
  sl.registerLazySingleton<DepartmentApiService>(() => DepartmentApiService(sl()));
  sl.registerLazySingleton<AttendanceApiService>(() => AttendanceApiService(sl()));

  // ── Blocs (registerFactory — each screen gets a fresh instance) ──
  sl.registerFactory<EmployeeBloc>(() => EmployeeBloc(sl()));
  sl.registerFactory<LeaveBloc>(() => LeaveBloc(sl()));
  sl.registerFactory<AttendanceBloc>(() => AttendanceBloc(sl()));
}
