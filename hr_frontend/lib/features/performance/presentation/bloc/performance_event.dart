// lib/features/performance/presentation/bloc/performance_event.dart

import 'package:flutter/foundation.dart';
import '../../data/models/performance_model.dart';

@immutable
abstract class PerformanceEvent {}

class LoadPerformanceReviewsEvent extends PerformanceEvent {}

class CreatePerformanceReviewEvent extends PerformanceEvent {
  final PerformanceReview review;
  CreatePerformanceReviewEvent(this.review);
}

class UpdatePerformanceReviewEvent extends PerformanceEvent {
  final String reviewId;
  final Map<String, dynamic> updates;
  UpdatePerformanceReviewEvent(this.reviewId, this.updates);
}

class DeletePerformanceReviewEvent extends PerformanceEvent {
  final String reviewId;
  DeletePerformanceReviewEvent(this.reviewId);
}
