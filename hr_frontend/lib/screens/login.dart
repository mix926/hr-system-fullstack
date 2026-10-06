import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'register.dart';
import '../services/api_service.dart'; // NEW: Import ApiService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService(); // NEW: Add API Service

  String email = '';
  String password = '';
  bool isLoading = false; // NEW: Track loading state

  // NEW: Updated to async function to call backend
  // ថ្មី៖ កែប្រែជាមុខងារ async ដើម្បីហៅទៅកាន់ Backend
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isLoading = true; // Show loading spinner
      });

      try {
        // Send login request to FastAPI
        // បញ្ជូនសំណើ Login ទៅកាន់ FastAPI
        await apiService.login(email, password);

        if (mounted) {
          // Success! Go to Dashboard
          // ជោគជ័យ! ចូលទៅកាន់ផ្ទាំង Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          // Show error message (like "Invalid password")
          // បង្ហាញសារកំហុស (ឧទាហរណ៍ "លេខសម្ងាត់មិនត្រឹមត្រូវ")
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false; // Hide loading spinner
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_person, size: 80, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'HR System Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter email' : null,
                      onSaved: (value) => email = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter password' : null,
                      onSaved: (value) => password = value!,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text("Don't have an account? Register here"),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Disable button while loading / បិទប៊ូតុងពេលកំពុងផ្ទុក
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}