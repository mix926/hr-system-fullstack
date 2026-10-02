import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../utils/constants.dart'; // Import constants file | បញ្ចូលឯកសារ constants

class ApiService {
  // Use the URL from AppConstants | ប្រើប្រាស់ URL ពី AppConstants
  static const String baseUrl = AppConstants.baseUrl;

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