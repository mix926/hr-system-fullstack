class Employee {
  final String? id;  // UUID from backend
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String role;
  final bool isActive;
  final String? password;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.role = 'STAFF',
    this.isActive = true,
    this.password,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString(),
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      position: json['position'],
      role: json['role'] ?? 'STAFF',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'position': position,
      'role': role,
    };

    if (password != null) {
      data['password'] = password;
    }

    return data;
  }
}