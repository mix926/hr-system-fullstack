import 'package:flutter/foundation.dart';

import '../data/employee_api_service.dart';
import 'employee_event.dart';
import 'employee_state.dart';

class EmployeeBloc extends ChangeNotifier {
  final EmployeeApiService _apiService;

  EmployeeState _state = EmployeeInitialState();
  EmployeeState get state => _state;

  EmployeeBloc(this._apiService);

  void _emit(EmployeeState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> add(EmployeeEvent event) async {
    if (event is LoadEmployeesEvent) {
      await _onLoadEmployees();
    } else if (event is CreateEmployeeEvent) {
      await _onCreateEmployee(event);
    } else if (event is DeleteEmployeeEvent) {
      await _onDeleteEmployee(event);
    }
  }

  Future<void> _onLoadEmployees() async {
    _emit(EmployeeLoadingState());
    final result = await _apiService.getEmployees();
    result.fold(
      (failure) => _emit(EmployeeErrorState(failure.message)),
      (employees) => _emit(EmployeeLoadedState(employees)),
    );
  }

  Future<void> _onCreateEmployee(CreateEmployeeEvent event) async {
    _emit(EmployeeLoadingState());
    final result = await _apiService.createEmployee(event.employee);
    result.fold(
      (failure) => _emit(EmployeeErrorState(failure.message)),
      (success) async {
        _emit(EmployeeOperationSuccessState('បង្កើតបុគ្គលិកបានជោគជ័យ!'));
        await _onLoadEmployees();
      },
    );
  }

  Future<void> _onDeleteEmployee(DeleteEmployeeEvent event) async {
    final result = await _apiService.deleteEmployee(event.id);
    result.fold(
      (failure) => _emit(EmployeeErrorState(failure.message)),
      (success) async {
        _emit(EmployeeOperationSuccessState('លុបបុគ្គលិកបានជោគជ័យ!'));
        await _onLoadEmployees();
      },
    );
  }
}
