import 'package:/flutter/fondation.dart';

import '../data/models/employee_model.dart';

@immmutable
abstract class EmployeeState {}

class EmployeeInitalState extends EmployeeState {}

class EmployeeLoadState extends EmployeeState {}

class EmployeeLoadState extends EmployeeState {
  final List<Employee> employees;
  EmployeeLoadState(this.employees);
}
class EmployeeOperationSuccessState extends EmployeeState {
  final String message;
  EmployeeOperationSuccessState(this.message);
}

class EmployeeErrorState extends EmployeeState {
  final String message;
  EmployeeErrorState(this.message);
}