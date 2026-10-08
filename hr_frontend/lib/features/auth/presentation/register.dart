// ខ្មែរ: ទីតាំងឯកសារ lib/features/auth/presentation/register.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'login.dart';
import '../data/auth_api_service.dart';
import '../../employee/data/models/employee_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ខ្មែរ: ទទួលយក AuthApiService ពី GetIt Service Locator
  final AuthApiService _authApiService = GetIt.instance<AuthApiService>();

  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String position = '';

  // ខ្មែរ: តួនាទីដើម (Default) ត្រូវតែជា STAFF ដើម្បីត្រូវនឹង Backend
  String role = 'STAFF';
  bool isLoading = false;

  // ខ្មែរ: បញ្ជីតួនាទីត្រូវតែជាអក្សរធំ ឱ្យដូចគ្នាទៅនឹង RoleEnum នៅក្នុង FastAPI
  final List<String> roles = ['ADMIN', 'MANAGER', 'STAFF'];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final newEmployee = Employee(
      firstName: firstName,
      lastName: lastName,
      email: email,
      position: position,
      password: password,
      role: role,
    );

    final result = await _authApiService.registerEmployee(newEmployee);

    if (!mounted) return;
    setState(() => isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                onSaved: (value) => firstName = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                onSaved: (value) => lastName = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
                onSaved: (value) => email = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value!.length < 8 ? 'Min 8 characters required' : null,
                onSaved: (value) => password = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Job Position', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter position' : null,
                onSaved: (value) => position = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                items: roles.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => role = newValue!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Register', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
