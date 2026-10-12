import 'package:flutter/foundation.dart';

import '../data/models/employee_model.dart';

@immutable
abstract class EmployeeEvent {}

class LoadEmployeesEvent extends EmployeeEvent {}

class CreateEmployeeEvent extends EmployeeEvent {
  final Employee employee;
  CreateEmployeeEvent(this.employee);
}

class DeleteEmployeeEvent extends EmployeeEvent {
  final String id;
  DeleteEmployeeEvent(this.id);
}
