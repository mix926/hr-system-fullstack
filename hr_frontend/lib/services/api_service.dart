import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../utils/constants.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use the URL from AppConstants | ប្រើប្រាស់ URL ពី AppConstants
  static const String baseUrl = AppConstants.baseUrl;

Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Save the token and role securely on the device
      // រក្សាទុក Token និង Role ក្នុងម៉ាស៊ីនឱ្យមានសុវត្ថិភាព
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      await prefs.setString('role', data['user']['role']);
      
      return data;
    } else {
      // If login fails, throw an error to show in the UI
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }
  // GET /employees/
  Future<List<Employee>> getEmployees() async {
    final response = await http.get(Uri.parse('$baseUrl/employees/'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Employee.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load employees');
    }
  }

  // POST /employees/
  Future<Employee> createEmployee(Employee employee) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employees/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(employee.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Employee.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create employee');
      
    }
  }
  // DELETE /employees/{id}
  Future<void> deleteEmployee(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/employees/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete employee');
    }
  }
}
