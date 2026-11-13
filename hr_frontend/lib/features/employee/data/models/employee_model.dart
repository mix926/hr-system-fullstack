// lib/features/employee/data/models/employee_model.dart

class Employee {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String position;
  final String? password;
  final String role;
  final String? departmentId;
  final String? designationId;
  final String? managerId;
  // Lifecycle
  final String? status;        // ONBOARDING | ACTIVE | ON_LEAVE | RESIGNED | TERMINATED | PROBATION
  final bool? isActive;
  // Extended personal info
  final String? phone;
  final String? address;
  final String? photoPath;
  final String? dateOfBirth;
  final String? hireDate;
  final String? exitDate;
  // Timestamps
  final String? createdAt;
  final String? updatedAt;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.position,
    this.password,
    this.role = 'STAFF',
    this.departmentId,
    this.designationId,
    this.managerId,
    this.status,
    this.isActive,
    this.phone,
    this.address,
    this.photoPath,
    this.dateOfBirth,
    this.hireDate,
    this.exitDate,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id:            json['id']?.toString(),
      firstName:     json['first_name'] ?? '',
      lastName:      json['last_name'] ?? '',
      email:         json['email'] ?? '',
      position:      json['position'] ?? '',
      role:          json['role'] ?? 'STAFF',
      departmentId:  json['department_id']?.toString(),
      designationId: json['designation_id']?.toString(),
      managerId:     json['manager_id']?.toString(),
      status:        json['status']?.toString(),
      isActive:      json['is_active'] as bool?,
      phone:         json['phone']?.toString(),
      address:       json['address']?.toString(),
      photoPath:     json['photo_path']?.toString(),
      dateOfBirth:   json['date_of_birth']?.toString(),
      hireDate:      json['hire_date']?.toString(),
      exitDate:      json['exit_date']?.toString(),
      createdAt:     json['created_at']?.toString(),
      updatedAt:     json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'first_name': firstName,
      'last_name':  lastName,
      'email':      email,
      'position':   position,
      'role':       role,
    };
    if (password != null && password!.isNotEmpty) data['password']       = password;
    if (departmentId  != null) data['department_id']  = departmentId;
    if (designationId != null) data['designation_id'] = designationId;
    if (managerId     != null) data['manager_id']     = managerId;
    if (phone         != null) data['phone']          = phone;
    if (address       != null) data['address']        = address;
    if (photoPath     != null) data['photo_path']     = photoPath;
    if (dateOfBirth   != null) data['date_of_birth']  = dateOfBirth;
    if (hireDate      != null) data['hire_date']      = hireDate;
    return data;
  }

  Employee copyWith({
    String? id, String? firstName, String? lastName, String? email,
    String? position, String? password, String? role, String? departmentId,
    String? designationId, String? managerId, String? status, bool? isActive,
    String? phone, String? address, String? photoPath, String? dateOfBirth,
    String? hireDate, String? exitDate, String? createdAt, String? updatedAt,
  }) {
    return Employee(
      id:            id            ?? this.id,
      firstName:     firstName     ?? this.firstName,
      lastName:      lastName      ?? this.lastName,
      email:         email         ?? this.email,
      position:      position      ?? this.position,
      password:      password      ?? this.password,
      role:          role          ?? this.role,
      departmentId:  departmentId  ?? this.departmentId,
      designationId: designationId ?? this.designationId,
      managerId:     managerId     ?? this.managerId,
      status:        status        ?? this.status,
      isActive:      isActive      ?? this.isActive,
      phone:         phone         ?? this.phone,
      address:       address       ?? this.address,
      photoPath:     photoPath     ?? this.photoPath,
      dateOfBirth:   dateOfBirth   ?? this.dateOfBirth,
      hireDate:      hireDate      ?? this.hireDate,
      exitDate:      exitDate      ?? this.exitDate,
      createdAt:     createdAt     ?? this.createdAt,
      updatedAt:     updatedAt     ?? this.updatedAt,
    );
  }
}

// ── Employee Document model ───────────────────────────────────

class EmployeeDocument {
  final String? id;
  final String employeeId;
  final String documentType;
  final String title;
  final String filePath;
  final String fileName;
  final String? expiryDate;
  final String? issuedDate;
  final String? issuingAuthority;
  final String? notes;
  final String? uploadedBy;
  final String? createdAt;

  EmployeeDocument({
    this.id,
    required this.employeeId,
    required this.documentType,
    required this.title,
    required this.filePath,
    required this.fileName,
    this.expiryDate,
    this.issuedDate,
    this.issuingAuthority,
    this.notes,
    this.uploadedBy,
    this.createdAt,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) => EmployeeDocument(
    id:               json['id']?.toString(),
    employeeId:       json['employee_id']?.toString() ?? '',
    documentType:     json['document_type']?.toString() ?? '',
    title:            json['title']?.toString() ?? '',
    filePath:         json['file_path']?.toString() ?? '',
    fileName:         json['file_name']?.toString() ?? '',
    expiryDate:       json['expiry_date']?.toString(),
    issuedDate:       json['issued_date']?.toString(),
    issuingAuthority: json['issuing_authority']?.toString(),
    notes:            json['notes']?.toString(),
    uploadedBy:       json['uploaded_by']?.toString(),
    createdAt:        json['created_at']?.toString(),
  );
}

// ── Designation model ─────────────────────────────────────────

class Designation {
  final String? id;
  final String name;
  final String? departmentId;
  final String? grade;
  final String? description;
  final bool isActive;

  Designation({
    this.id,
    required this.name,
    this.departmentId,
    this.grade,
    this.description,
    this.isActive = true,
  });

  factory Designation.fromJson(Map<String, dynamic> json) => Designation(
    id:           json['id']?.toString(),
    name:         json['name']?.toString() ?? '',
    departmentId: json['department_id']?.toString(),
    grade:        json['grade']?.toString(),
    description:  json['description']?.toString(),
    isActive:     json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (departmentId != null) 'department_id': departmentId,
    if (grade        != null) 'grade':         grade,
    if (description  != null) 'description':   description,
    'is_active': isActive,
  };
}

// ── Org chart node ────────────────────────────────────────────

class OrgNode {
  final String id;
  final String firstName;
  final String lastName;
  final String? position;
  final String? managerId;

  OrgNode({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.position,
    this.managerId,
  });

  String get fullName => '$firstName $lastName';

  factory OrgNode.fromJson(Map<String, dynamic> json) => OrgNode(
    id:        json['id']?.toString() ?? '',
    firstName: json['first_name']?.toString() ?? '',
    lastName:  json['last_name']?.toString() ?? '',
    position:  json['position']?.toString(),
    managerId: json['manager_id']?.toString(),
  );
}
