// Location: lib/features/employee/presentation/bloc/employee_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/employee_api_service.dart';
import 'employee_event.dart';
import 'employee_state.dart';

/// ខ្មែរ: EmployeeBloc ប្រើ flutter_bloc (Bloc<Event,State>) ដូចគ្នាទៅ LeaveBloc
class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  final EmployeeApiService _apiService;

  EmployeeBloc(this._apiService) : super(EmployeeInitialState()) {
    on<LoadEmployeesEvent>(_onLoadEmployees);
    on<CreateEmployeeEvent>(_onCreateEmployee);
    on<DeleteEmployeeEvent>(_onDeleteEmployee);
  }

  Future<void> _onLoadEmployees(
    LoadEmployeesEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoadingState());
    final result = await _apiService.getEmployees();
    result.fold(
      (failure) => emit(EmployeeErrorState(failure.message)),
      (employees) => emit(EmployeeLoadedState(employees)),
    );
  }

  Future<void> _onCreateEmployee(
    CreateEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    emit(EmployeeLoadingState());
    final result = await _apiService.createEmployee(event.employee);
    result.fold(
      (failure) => emit(EmployeeErrorState(failure.message)),
      (success) {
        emit(EmployeeOperationSuccessState('បង្កើតបុគ្គលិកបានជោគជ័យ!'));
        add(LoadEmployeesEvent());
      },
    );
  }

  Future<void> _onDeleteEmployee(
    DeleteEmployeeEvent event,
    Emitter<EmployeeState> emit,
  ) async {
    final result = await _apiService.deleteEmployee(event.id);
    result.fold(
      (failure) => emit(EmployeeErrorState(failure.message)),
      (success) {
        emit(EmployeeOperationSuccessState('លុបបុគ្គលិកបានជោគជ័យ!'));
        add(LoadEmployeesEvent());
      },
    );
  }
}
