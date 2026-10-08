// ខ្មែរ: ទីតាំងឯកសារ lib/core/network/api_interceptor.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ខ្មែរ: AuthInterceptor ទទួលបន្ទុកក្នុងការភ្ជាប់ Token ទៅរាល់ Request
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // ខ្មែរ: ទាញយក Token ពីម៉ាស៊ីន (Local Storage)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // ខ្មែរ: បើមាន Token, ភ្ជាប់វាទៅក្នុង Header
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // ខ្មែរ: កំណត់ទម្រង់ទិន្នន័យជា JSON ជានិច្ច
    options.headers['Content-Type'] = 'application/json';
    
    // ខ្មែរ: អនុញ្ញាតអោយ Request បន្តដំណើរទៅកាន់ Server
    super.onRequest(options, handler);
  }
}