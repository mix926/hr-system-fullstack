import 'package:flutter/foundation.dart';

import '../data/models/employee_model.dart';

@immutable
abstract class EmployeeState {}

class EmployeeInitialState extends EmployeeState {}

class EmployeeLoadingState extends EmployeeState {}

class EmployeeLoadedState extends EmployeeState {
  final List<Employee> employees;
  EmployeeLoadedState(this.employees);
}

class EmployeeOperationSuccessState extends EmployeeState {
  final String message;
  EmployeeOperationSuccessState(this.message);
}

class EmployeeErrorState extends EmployeeState {
  final String message;
  EmployeeErrorState(this.message);
}
