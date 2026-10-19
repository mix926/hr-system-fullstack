// lib/features/performance/presentation/bloc/performance_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/performance_api_service.dart';
import 'performance_event.dart';
import 'performance_state.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final PerformanceApiService _apiService;

  PerformanceBloc(this._apiService) : super(PerformanceInitialState()) {
    on<LoadPerformanceReviewsEvent>(_onLoadReviews);
    on<CreatePerformanceReviewEvent>(_onCreateReview);
    on<UpdatePerformanceReviewEvent>(_onUpdateReview);
    on<DeletePerformanceReviewEvent>(_onDeleteReview);
  }

  Future<void> _onLoadReviews(
      LoadPerformanceReviewsEvent event, Emitter<PerformanceState> emit) async {
    emit(PerformanceLoadingState());
    final result = await _apiService.getReviews();

    result.fold(
      (failure) => emit(PerformanceErrorState(failure.message)),
      (reviews) => emit(PerformanceLoadedState(reviews)),
    );
  }

  Future<void> _onCreateReview(
      CreatePerformanceReviewEvent event, Emitter<PerformanceState> emit) async {
    emit(PerformanceLoadingState());
    final result = await _apiService.createReview(event.review);

    result.fold(
      (failure) => emit(PerformanceErrorState(failure.message)),
      (success) {
        emit(PerformanceOperationSuccessState('Review created successfully!'));
        add(LoadPerformanceReviewsEvent());
      },
    );
  }

  Future<void> _onUpdateReview(
      UpdatePerformanceReviewEvent event, Emitter<PerformanceState> emit) async {
    final result = await _apiService.updateReview(event.reviewId, event.updates);
    result.fold(
      (failure) => emit(PerformanceErrorState(failure.message)),
      (success) {
        emit(PerformanceOperationSuccessState('Review updated successfully!'));
        add(LoadPerformanceReviewsEvent());
      },
    );
  }

  Future<void> _onDeleteReview(
      DeletePerformanceReviewEvent event, Emitter<PerformanceState> emit) async {
    final result = await _apiService.deleteReview(event.reviewId);
    result.fold(
      (failure) => emit(PerformanceErrorState(failure.message)),
      (success) {
        emit(PerformanceOperationSuccessState('Review deleted successfully!'));
        add(LoadPerformanceReviewsEvent());
      },
    );
  }
}
