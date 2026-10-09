// Location: lib/features/employee/data/models/employee_model.dart

class Employee {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String? password; // ខ្មែរ: ប្រើតែពេល Create/Register
  final String role;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.password,
    this.role = 'STAFF',
  });

  // ខ្មែរ: Helper Getter សម្រាប់ទាញយកឈ្មោះពេញមកបង្ហាញលើ UI
  String get fullName => '$firstName $lastName';

  // ខ្មែរ: បំប្លែងទិន្នន័យពី JSON (FastAPI Backend) ទៅជា Employee Object
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      position: json['position'] ?? '',
      role: json['role'] ?? 'STAFF',
    );
  }

  // ខ្មែរ: បំប្លែង Employee Object ទៅជា JSON ដើម្បីផ្ញើទៅ FastAPI Backend
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'position': position,
      'role': role,
    };
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    return data;
  }

  // ខ្មែរ: copyWith សម្រាប់ Update State ដោយមិនប៉ះពាល់ Original Object
  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? position,
    String? password,
    String? role,
  }) {
    return Employee(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      position: position ?? this.position,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}