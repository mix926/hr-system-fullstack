// lib/features/performance/presentation/bloc/performance_state.dart

import 'package:flutter/foundation.dart';
import '../../data/models/performance_model.dart';

@immutable
abstract class PerformanceState {}

class PerformanceInitialState extends PerformanceState {}

class PerformanceLoadingState extends PerformanceState {}

class PerformanceLoadedState extends PerformanceState {
  final List<PerformanceReview> reviews;
  PerformanceLoadedState(this.reviews);
}

class PerformanceOperationSuccessState extends PerformanceState {
  final String message;
  PerformanceOperationSuccessState(this.message);
}

class PerformanceErrorState extends PerformanceState {
  final String message;
  PerformanceErrorState(this.message);
}
