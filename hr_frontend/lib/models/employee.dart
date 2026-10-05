class Employee {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String role; // NEW FIELD: Admin, HR, or Employee / សិទ្ធិប្រើប្រាស់
  final bool isActive;
  final String? password; // NEW FIELD: For registration only / សម្រាប់តែពេលចុះឈ្មោះ

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.role = 'Employee', // Default role / សិទ្ធិស្វ័យប្រវត្តិ
    this.isActive = true,
    this.password, 
  });

  // Convert JSON to Employee object
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      position: json['position'],
      role: json['role'] ?? 'Employee',
      isActive: json['is_active'] ?? true,
    );
  }

  // Convert Employee object to JSON for POST requests
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'position': position,
      'role': role,
    };
    
    // Only add password to JSON if it was provided (important for registration)
    // បញ្ចូលលេខសម្ងាត់ទៅក្នុង JSON តែក្នុងករណីមានទិន្នន័យ (សំខាន់សម្រាប់ការចុះឈ្មោះ)
    if (password != null) {
      data['password'] = password;
    }
    
    return data;
  }
}