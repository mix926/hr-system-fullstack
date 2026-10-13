// Location: lib/core/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../features/auth/data/auth_api_service.dart';
import '../features/employee/data/employee_api_service.dart';
import '../features/leave/data/leave_api_service.dart';
// ខ្មែរ: ជួសជុល — import LeaveBloc ដើម្បីចុះឈ្មោះក្នុង Service Locator
import '../features/leave/presentation/bloc/leave_bloc.dart';
import 'network/api_interceptor.dart';
import 'utils/constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ខ្មែរ: ចុះឈ្មោះ Dio ជា Single Instance ដែលមាន Base URL និង Auth Interceptor
  sl.registerLazySingleton<Dio>(() {
    // ខ្មែរ: ប្រើ AppConstants.baseUrl ជា Single Source of Truth
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    dio.interceptors.add(AuthInterceptor());
    return dio;
  });

  // ខ្មែរ: ចុះឈ្មោះ API Services ទាំងអស់
  sl.registerLazySingleton<AuthApiService>(() => AuthApiService(sl()));
  sl.registerLazySingleton<EmployeeApiService>(() => EmployeeApiService(sl()));
  // ខ្មែរ: LeaveApiService ត្រូវបន្ថែមដើម្បីឱ្យ LeaveBloc អាចទាញប្រើបាន
  sl.registerLazySingleton<LeaveApiService>(() => LeaveApiService(sl()));

  // ខ្មែរ: ជួសជុល — ចុះឈ្មោះ LeaveBloc ដើម្បីឱ្យ UI អាច inject បាន
  sl.registerFactory<LeaveBloc>(() => LeaveBloc(sl()));
}
