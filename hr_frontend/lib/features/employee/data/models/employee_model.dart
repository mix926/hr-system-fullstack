// Location: lib/features/employee/data/models/employee_model.dart

class Employee {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String? password;
  final String role;
  final String? departmentId;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.password,
    this.role = 'STAFF',
    this.departmentId,
  });

  // ខ្មែរ: Helper Getter សម្រាប់ទាញយកឈ្មោះពេញមកបង្ហាញលើ UI
  String get fullName => '$firstName $lastName';

  // ខ្មែរ: បំប្លែងទិន្នន័យពី JSON (FastAPI Backend) ទៅជា Employee Object
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id:           json['id']?.toString(),
      firstName:    json['first_name'] ?? '',
      lastName:     json['last_name'] ?? '',
      email:        json['email'] ?? '',
      position:     json['position'] ?? '',
      role:         json['role'] ?? 'STAFF',
      departmentId: json['department_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name':  lastName,
      'email':      email,
      'position':   position,
      'role':       role,
    };
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    if (departmentId != null) {
      data['department_id'] = departmentId;
    }
    return data;
  }

  Employee copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? position,
    String? password,
    String? role,
    String? departmentId,
  }) {
    return Employee(
      id:           id           ?? this.id,
      firstName:    firstName    ?? this.firstName,
      lastName:     lastName     ?? this.lastName,
      email:        email        ?? this.email,
      position:     position     ?? this.position,
      password:     password     ?? this.password,
      role:         role         ?? this.role,
      departmentId: departmentId ?? this.departmentId,
    );
  }
}