// lib/core/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // API Base URL
  // iOS Simulator / macOS desktop: 'http://127.0.0.1:8000'
  // Android Emulator: 'http://10.0.2.2:8000'
  // Physical Phone: Use your Mac's Wi-Fi IP address (e.g., 'http://192.168.1.15:8000')
  static const String baseUrl = 'http://127.0.0.1:8000';

  // API Endpoints
  static const String loginEndpoint = '/api/v1/login';
  static const String registerEndpoint = '/api/v1/employees';
  static const String employeesEndpoint = '/api/v1/employees';

  // Secure Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';

  // Enterprise Theme Colors
  static const Color primaryColor = Color(0xFF2563EB); // Modern Professional Blue
  static const Color successColor = Color(0xFF16A34A); // Emerald Green
  static const Color errorColor = Color(0xFFDC2626);   // Modern Red
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate Light Background

  // Layout Constraints
  static const double defaultPadding = 16.0;
}