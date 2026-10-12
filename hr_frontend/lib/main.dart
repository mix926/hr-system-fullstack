// ខ្មែរ: ទីតាំងឯកសារ lib/main.dart
import 'package:flutter/material.dart';

import 'core/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HR System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const LoginScreen(),
    );
  }
}