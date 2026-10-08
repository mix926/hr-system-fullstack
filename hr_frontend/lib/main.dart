// ខ្មែរ: ទីតាំងឯកសារ lib/main.dart
import 'package:flutter/material.dart';

// ខ្មែរ: ទាញយកពីទីតាំងថ្មីដោយផ្អែកលើ Feature-First Architecture
import 'features/auth/presentation/login.dart';

// ខ្មែរ: ទាញយក Service Locator (GetIt) ដែលយើងបានបង្កើត
import 'core/injection_container.dart' as di; 

// ខ្មែរ: បន្ថែម async ពីព្រោះ di.init() ត្រូវការពេលវេលាដើម្បីដំណើរការ
void main() async {
  // ខ្មែរ: ត្រូវតែមានកូដនេះ ព្រោះយើងប្រើប្រាស់ await មុនពេល runApp()
  // ខ្មែរ: វាប្រាប់ Flutter អោយរៀបចំម៉ាស៊ីនវាអោយរួចរាល់សិន មុននឹងយើងហៅកូដ Async
  WidgetsFlutterBinding.ensureInitialized();
  
  // ខ្មែរ: បើកដំណើរការ Service Locator ដើម្បីរៀបចំ Dio និង Services ទុកជាមុន
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}