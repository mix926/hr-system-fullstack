// lib/features/performance/data/models/performance_model.dart

class PerformanceReview {
  // ── Review Period Constants ─────────────────────────────────
  static const String periodQ1 = 'Q1';
  static const String periodQ2 = 'Q2';
  static const String periodQ3 = 'Q3';
  static const String periodQ4 = 'Q4';
  static const String periodAnnual = 'Annual Review';
  static const String periodMidYear = 'Mid-Year Review';
  static const List<String> reviewPeriods = [periodQ1, periodQ2, periodQ3, periodQ4, periodAnnual, periodMidYear];

  final String? id;
  final String? employeeId;
  final String? reviewerId;
  final String reviewPeriod;
  final int rating;
  final String? strengths;
  final String? areasForImprovement;
  final String? goals;
  final String? comments;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  PerformanceReview({
    this.id,
    this.employeeId,
    this.reviewerId,
    required this.reviewPeriod,
    required this.rating,
    this.strengths,
    this.areasForImprovement,
    this.goals,
    this.comments,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    return PerformanceReview(
      id: json['id']?.toString(),
      employeeId: json['employee_id']?.toString(),
      reviewerId: json['reviewer_id']?.toString(),
      reviewPeriod: json['review_period'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      strengths: json['strengths'],
      areasForImprovement: json['areas_for_improvement'],
      goals: json['goals'],
      comments: json['comments'],
      status: json['status'] ?? 'SUBMITTED',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'review_period': reviewPeriod,
      'rating': rating,
      'strengths': strengths,
      'areas_for_improvement': areasForImprovement,
      'goals': goals,
      'comments': comments,
    };
  }

  PerformanceReview copyWith({
    String? id,
    String? employeeId,
    String? reviewerId,
    String? reviewPeriod,
    int? rating,
    String? strengths,
    String? areasForImprovement,
    String? goals,
    String? comments,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return PerformanceReview(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewPeriod: reviewPeriod ?? this.reviewPeriod,
      rating: rating ?? this.rating,
      strengths: strengths ?? this.strengths,
      areasForImprovement: areasForImprovement ?? this.areasForImprovement,
      goals: goals ?? this.goals,
      comments: comments ?? this.comments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
