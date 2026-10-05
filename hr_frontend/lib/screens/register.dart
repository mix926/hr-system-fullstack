import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/api_service.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  
  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String position = '';
  String role = 'Employee'; // Default role

  final List<String> roles = ['Admin', 'HR', 'Employee']; // 3 Roles

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final newEmployee = Employee(
        firstName: firstName,
        lastName: lastName,
        email: email,
        position: position,
        password: password,
        role: role,
      );

      try {
        await apiService.createEmployee(newEmployee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful! Please login.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
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
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
                onSaved: (value) => email = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Min 6 characters' : null,
                onSaved: (value) => password = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Job Position', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Enter position' : null,
                onSaved: (value) => position = value!,
              ),
              const SizedBox(height: 16),
              // ROLE DROPDOWN / ប្រអប់ជ្រើសរើសសិទ្ធិ
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                items: roles.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    role = newValue!;
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Text('Register', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}