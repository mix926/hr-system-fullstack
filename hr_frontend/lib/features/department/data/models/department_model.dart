// Location: lib/features/department/data/models/department_model.dart

class DepartmentModel {
  final String? id;
  final String name;
  final String? createdAt;

  DepartmentModel({this.id, required this.name, this.createdAt});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id:        json['id']?.toString(),
      name:      json['name'] ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}
