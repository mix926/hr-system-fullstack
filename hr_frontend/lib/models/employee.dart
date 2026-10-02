class Employee {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final bool isActive;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.isActive = true,
  });

  // Convert JSON to Employee object
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      position: json['position'],
      isActive: json['is_active'] ?? true,
    );
  }

  // Convert Employee object to JSON for POST requests
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'position': position,
    };
  }
}