import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../services/api_service.dart';
import 'add_employee.dart';
import 'login.dart';

import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Employee>> futureEmployees;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role') ?? '';
    });
  }
  void _loadEmployees() {
    setState(() {
      futureEmployees = apiService.getEmployees();
    });
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
              // 1. Clear the saved token and role / លុបទិន្នន័យ Token និង Role ដែលបានរក្សាទុក
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (context.mounted) {
                // 2. Navigate back to Login Screen / ត្រឡប់ទៅកាន់ផ្ទាំង Login វិញ
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Employee>>(
        future: futureEmployees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No employees found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final emp = snapshot.data![index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(emp.firstName[0].toUpperCase()),
                  ),
                  title: Text('${emp.firstName} ${emp.lastName}'),
                  subtitle: Text('${emp.position} | ${emp.email}'),
                  // NEW DELETE BUTTON | ប៊ូតុងលុបថ្មី
                 trailing: userRole == 'ADMIN'
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await apiService.deleteEmployee(emp.id!);
                              _loadEmployees(); // Reload list after deleting
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Employee deleted successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'))
                                );
                              }
                            }
                          },
                        )
                      : null, // Hide if not admin | លាក់វាបើមិនមែន admin
                ),
              );
            },
          );
        },
      ),
      // ONLY show Add button if role is admin | បង្ហាញប៊ូតុង Add តែពេលសិទ្ធិជា admin ប៉ុណ្ណោះ
      floatingActionButton: userRole == 'ADMIN'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
                );
                // Refresh the list if a new employee was added
                if (result == true) {
                  _loadEmployees();
                }
              },
              child: const Icon(Icons.add),
            )
          : null, // Hide if not admin | លាក់វាបើមិនមែន admin
    );
  }
}
     