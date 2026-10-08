// Location: lib/features/auth/employee/data/models/employee_model.dart

class Employee {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String? password; // ខ្មែរ: ប្រើតែពេល Create/Register, Server នឹងមិនប្រើពេល Get
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

  // ខ្មែរ: បំប្លែងទិន្នន័យពី JSON (Server) ទៅជា Employee Object
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

  // ខ្មែរ: បំប្លែង Employee Object ទៅជា JSON ដើម្បីផ្ញើទៅ Server
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'position': position,
      'role': role,
    };
    // ខ្មែរ: បន្ថែម password តែពេលដែលមានតម្លៃ (ពេល Create/Register)
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    return data;
  }
}
