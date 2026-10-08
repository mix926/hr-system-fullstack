import 'package:flutter/material.dart';

class AppConstants {
  // API Base URL
  // iOS Simulator / macOS desktop: 'http://127.0.0.1:8000'
  // Android Emulator: 'http://10.0.2.2:8000'
  // Physical Phone: Use your Mac's Wi-Fi IP address (e.g., 'http://192.168.1.15:8000')
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Theme Colors
  static const Color primaryColor = Colors.blue;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Layout Constraints
  static const double defaultPadding = 16.0;
}