// ខ្មែរ: ទីតាំងឯកសារ lib/features/auth/employee/presentation/add_employee.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/employee_api_service.dart';
import '../data/models/employee_model.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // ខ្មែរ: ទទួលយក EmployeeApiService ពី GetIt Service Locator
  final EmployeeApiService _employeeApiService = GetIt.instance<EmployeeApiService>();

  String firstName = '';
  String lastName = '';
  String email = '';
  String position = '';
  String password = '';
  String role = 'STAFF';

  bool isLoading = false;
  final List<String> roles = ['ADMIN', 'MANAGER', 'STAFF'];

  void _submitForm() async {
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

    final result = await _employeeApiService.createEmployee(newEmployee);

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
            content: Text('Employee added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter first name' : null,
                onSaved: (value) => firstName = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter last name' : null,
                onSaved: (value) => lastName = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter email';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
                onSaved: (value) => email = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Position', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter position' : null,
                onSaved: (value) => position = value!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Temporary Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value!.length < 8 ? 'Min 8 characters required' : null,
                onSaved: (value) => password = value!,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                items: roles.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) => setState(() => role = newValue!),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Save Employee', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
