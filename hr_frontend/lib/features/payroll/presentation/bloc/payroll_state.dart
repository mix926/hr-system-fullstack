// lib/features/payroll/presentation/bloc/payroll_state.dart

import 'package:flutter/foundation.dart';
import '../../data/models/payroll_model.dart';

@immutable
abstract class PayrollState {}

class PayrollInitialState extends PayrollState {}

class PayrollLoadingState extends PayrollState {}

class PayrollLoadedState extends PayrollState {
  final List<PayrollModel> payrolls;
  PayrollLoadedState(this.payrolls);
}

class PayrollStatsLoadedState extends PayrollState {
  final List<PayrollModel> payrolls;
  final Map<String, dynamic> stats;
  PayrollStatsLoadedState(this.payrolls, this.stats);
}

class PayrollOperationSuccessState extends PayrollState {
  final String message;
  PayrollOperationSuccessState(this.message);
}

class PayrollErrorState extends PayrollState {
  final String message;
  PayrollErrorState(this.message);
}
