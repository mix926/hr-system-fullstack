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
import '../features/performance/data/performance_enhanced_api_service.dart';
import '../features/performance/presentation/bloc/performance_bloc.dart';
import '../features/payroll/data/payroll_api_service.dart';
import '../features/payroll/presentation/bloc/payroll_bloc.dart';
import '../features/recruitment/data/recruitment_api_service.dart';
import '../features/recruitment/presentation/bloc/recruitment_bloc.dart';
import '../features/notification/data/notification_api_service.dart';
import '../features/notification/presentation/bloc/notification_bloc.dart';
import '../features/reports/data/reports_api_service.dart';
import '../features/reports/presentation/bloc/reports_bloc.dart';
import '../features/admin/data/admin_api_service.dart';
import '../features/admin/presentation/bloc/admin_bloc.dart';
import 'network/api_interceptor.dart';
import 'network/secure_api_client.dart';
import 'rbac/auth_session.dart';
import 'utils/constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── RBAC Core ────────────────────────────────────────────────
  sl.registerSingleton<AuthSession>(AuthSession.instance);

  // ── Network ──────────────────────────────────────────────────
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    dio.interceptors.add(AuthInterceptor());
    return dio;
  });
  sl.registerLazySingleton<SecureApiClient>(() => SecureApiClient(sl<Dio>()));

  // ── API Services ─────────────────────────────────────────────
  sl.registerLazySingleton<AuthApiService>(()       => AuthApiService(sl()));
  sl.registerLazySingleton<EmployeeApiService>(()   => EmployeeApiService(sl()));
  sl.registerLazySingleton<LeaveApiService>(()      => LeaveApiService(sl()));
  sl.registerLazySingleton<DepartmentApiService>(() => DepartmentApiService(sl()));
  sl.registerLazySingleton<AttendanceApiService>(() => AttendanceApiService(sl()));
  sl.registerLazySingleton<PerformanceApiService>(() => PerformanceApiService(sl()));
  sl.registerLazySingleton<PerformanceEnhancedApiService>(
      () => PerformanceEnhancedApiService(sl()));
  sl.registerLazySingleton<PayrollApiService>(()    => PayrollApiService(sl()));
  sl.registerLazySingleton<RecruitmentApiService>(() => RecruitmentApiService(sl()));
  sl.registerLazySingleton<NotificationApiService>(() => NotificationApiService(sl()));
  sl.registerLazySingleton<ReportsApiService>(()    => ReportsApiService(sl()));
  sl.registerLazySingleton<AdminApiService>(()      => AdminApiService(sl()));

  // ── BLoCs ─────────────────────────────────────────────────────
  // AuthBloc is a singleton — auth state must persist app-wide.
  sl.registerSingleton<AuthBloc>(AuthBloc(sl<AuthApiService>()));

  // All feature BLoCs are factories — fresh instance per screen.
  sl.registerFactory<EmployeeBloc>(()   => EmployeeBloc(sl()));
  sl.registerFactory<LeaveBloc>(()      => LeaveBloc(sl()));
  sl.registerFactory<AttendanceBloc>(() => AttendanceBloc(sl()));
  sl.registerFactory<PerformanceBloc>(() => PerformanceBloc(sl()));
  sl.registerFactory<PayrollBloc>(()    => PayrollBloc(sl()));
  sl.registerFactory<RecruitmentBloc>(() => RecruitmentBloc(sl()));
  sl.registerFactory<NotificationBloc>(() => NotificationBloc(sl()));
  sl.registerFactory<ReportsBloc>(()    => ReportsBloc(sl()));
  sl.registerFactory<AdminBloc>(()      => AdminBloc(sl()));
}
