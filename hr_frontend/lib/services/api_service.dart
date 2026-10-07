import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../utils/constants.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  // POST /login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      await prefs.setString('role', data['user']['role']);
      
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  // GET /employees/
  Future<List<Employee>> getEmployees() async {
    // 1. Get the saved token / ទាញយក Token ដែលបានរក្សាទុក
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/employees/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Employee.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load employees');
    }
  }

  // POST /employees/
  Future<Employee> createEmployee(Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // 1. Get the token / ទាញយក Token

    print("POST TOKEN CHECK: $token"); // Debug check / ពិនិត្យមើលក្នុង Terminal

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/employees/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // 2. SEND THE TOKEN / បញ្ជូន Token 
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
  Future<void> deleteEmployee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // <-- GET TOKEN

    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/employees/$id'),
      headers: {
        'Authorization': 'Bearer $token', // <-- SEND TOKEN HERE / បញ្ជូន Token នៅទីនេះ
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete employee');
    }
  }
}