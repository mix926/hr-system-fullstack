// lib/core/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../features/auth/data/auth_api_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/employee/data/employee_api_service.dart';
import '../features/employee/presentation/bloc/employee_bloc.dart';
import '../features/leave/data/leave_api_service.dart';
import '../features/leave/presentation/bloc/leave_bloc.dart';
import '../features/department/data/department_api_service.dart';
import '../features/attendance/data/attendance_api_service.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../features/performance/data/performance_api_service.dart';
import '../features/performance/presentation/bloc/performance_bloc.dart';
import '../features/payroll/data/payroll_api_service.dart';
import '../features/payroll/presentation/bloc/payroll_bloc.dart';
import 'network/api_interceptor.dart';
import 'network/secure_api_client.dart';
import 'rbac/auth_session.dart';
import 'utils/constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── RBAC Core ────────────────────────────────────────────────
  // AuthSession is a singleton — register the instance directly.
  sl.registerSingleton<AuthSession>(AuthSession.instance);

  // ── Network ──────────────────────────────────────────────────
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    dio.interceptors.add(AuthInterceptor());
    return dio;
  });

  // SecureApiClient wraps Dio with RBAC permission checks.
  sl.registerLazySingleton<SecureApiClient>(() => SecureApiClient(sl<Dio>()));

  // ── API Services ─────────────────────────────────────────────
  sl.registerLazySingleton<AuthApiService>(() => AuthApiService(sl()));
  sl.registerLazySingleton<EmployeeApiService>(() => EmployeeApiService(sl()));
  sl.registerLazySingleton<LeaveApiService>(() => LeaveApiService(sl()));
  sl.registerLazySingleton<DepartmentApiService>(() => DepartmentApiService(sl()));
  sl.registerLazySingleton<AttendanceApiService>(() => AttendanceApiService(sl()));
  sl.registerLazySingleton<PerformanceApiService>(() => PerformanceApiService(sl()));
  sl.registerLazySingleton<PayrollApiService>(() => PayrollApiService(sl()));

  // ── Blocs (registerFactory — each screen gets a fresh instance) ──
  // AuthBloc is registered as a singleton so the auth state persists
  // across screen transitions and is available app-wide.
  sl.registerSingleton<AuthBloc>(AuthBloc(sl<AuthApiService>()));

  sl.registerFactory<EmployeeBloc>(() => EmployeeBloc(sl()));
  sl.registerFactory<LeaveBloc>(() => LeaveBloc(sl()));
  sl.registerFactory<AttendanceBloc>(() => AttendanceBloc(sl()));
  sl.registerFactory<PerformanceBloc>(() => PerformanceBloc(sl()));
  sl.registerFactory<PayrollBloc>(() => PayrollBloc(sl()));
}
