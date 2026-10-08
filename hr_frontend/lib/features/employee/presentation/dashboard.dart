// ខ្មែរ: ទីតាំងឯកសារ lib/features/auth/employee/presentation/dashboard.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

import '../data/employee_api_service.dart';
import '../data/models/employee_model.dart';
import '../../auth/presentation/login.dart';
import 'add_employee.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ខ្មែរ: ទទួលយក EmployeeApiService ពី GetIt Service Locator
  final EmployeeApiService _employeeApiService = GetIt.instance<EmployeeApiService>();

  List<Employee> employees = [];
  bool isLoading = true;
  String? errorMessage;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userRole = prefs.getString('role') ?? '');
    await _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _employeeApiService.getEmployees();

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          isLoading = false;
          errorMessage = failure.message;
        });
      },
      (data) {
        setState(() {
          isLoading = false;
          employees = data;
        });
      },
    );
  }

  Future<void> _deleteEmployee(String id) async {
    final result = await _employeeApiService.deleteEmployee(id);

    if (!mounted) return;

    // ignore: use_build_context_synchronously
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadEmployees();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (mounted) {
                nav.pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: userRole == 'ADMIN'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
                );
                if (result == true) {
                  _loadEmployees();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $errorMessage', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadEmployees, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (employees.isEmpty) {
      return const Center(child: Text('No employees found.'));
    }

    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : '?'),
            ),
            title: Text('${emp.firstName} ${emp.lastName}'),
            subtitle: Text('${emp.position} | ${emp.email}'),
            trailing: userRole == 'ADMIN'
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEmployee(emp.id ?? ''),
                  )
                : null,
          ),
        );
      },
    );
  }
}
