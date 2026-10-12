import 'package:flutter/material.dart';
import 'package:hr_frontend/features/employee/data/models/employee_model.dart';

import '../data/models/employee_model.dart';

@immutable
abstract class EmployeeEvent {}

class LoadEmployeeEvent extends EmployeeEvent {}

class LoadEmployeeEvent extends EmployeeEvent {
  final Employee employee;
  CreateEmployeeeEvent(this.employee);
}

class DeleteEmployeeEvent extends EmployeeEvent {
  final String id;
  DeleteEmployeeEvent(this.id);
}
