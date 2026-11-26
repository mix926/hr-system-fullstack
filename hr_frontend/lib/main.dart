// ខ្មែរ: ទីតាំងឯកសារ lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login.dart';

/// Global theme notifier — readable from anywhere via [themeNotifier].
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Restore saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  }

  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  static const String version = '2.0.0';
  static const String appName = 'HR System Pro';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'HR System Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        darkTheme: AppTheme.darkThemeData,
        themeMode: mode,
        home: const LoginScreen(),
      ),
    );
  }
}
