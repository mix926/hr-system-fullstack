// lib/features/payroll/presentation/bloc/payroll_event.dart

import 'package:flutter/foundation.dart';
import '../../data/models/payroll_model.dart';

@immutable
abstract class PayrollEvent {}

class LoadPayrollsEvent extends PayrollEvent {}

class LoadPayrollStatsEvent extends PayrollEvent {}

class CreatePayrollEvent extends PayrollEvent {
  final PayrollModel payroll;
  CreatePayrollEvent(this.payroll);
}

class UpdatePayrollEvent extends PayrollEvent {
  final int payrollId;
  final double? baseSalary;
  final double? bonus;
  final double? deductions;

  UpdatePayrollEvent({
    required this.payrollId,
    this.baseSalary,
    this.bonus,
    this.deductions,
  });
}

class UpdatePayrollStatusEvent extends PayrollEvent {
  final int payrollId;
  final String status;
  UpdatePayrollStatusEvent(this.payrollId, this.status);
}

class DeletePayrollEvent extends PayrollEvent {
  final int payrollId;
  DeletePayrollEvent(this.payrollId);
}
