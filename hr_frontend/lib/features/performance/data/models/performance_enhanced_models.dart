// lib/features/performance/data/models/performance_enhanced_models.dart

class PerformanceGoal {
  final String? id;
  final String employeeId;
  final String? parentGoalId;
  final String title;
  final String? description;
  final String goalType;
  final String status;
  final double? targetValue;
  final double currentValue;
  final String? unit;
  final double weight;
  final String period;
  final String? startDate;
  final String? endDate;
  final String? createdAt;

  PerformanceGoal({
    this.id, required this.employeeId, this.parentGoalId,
    required this.title, this.description, this.goalType = 'OKR',
    this.status = 'DRAFT', this.targetValue, this.currentValue = 0.0,
    this.unit, this.weight = 1.0, required this.period,
    this.startDate, this.endDate, this.createdAt,
  });

  double get progressPercent {
    if (targetValue == null || targetValue == 0) return 0;
    return (currentValue / targetValue! * 100).clamp(0, 100);
  }

  factory PerformanceGoal.fromJson(Map<String, dynamic> j) => PerformanceGoal(
    id: j['id']?.toString(), employeeId: j['employee_id']?.toString() ?? '',
    parentGoalId: j['parent_goal_id']?.toString(), title: j['title']?.toString() ?? '',
    description: j['description']?.toString(), goalType: j['goal_type']?.toString() ?? 'OKR',
    status: j['status']?.toString() ?? 'DRAFT',
    targetValue: (j['target_value'] as num?)?.toDouble(),
    currentValue: (j['current_value'] as num?)?.toDouble() ?? 0.0,
    unit: j['unit']?.toString(), weight: (j['weight'] as num?)?.toDouble() ?? 1.0,
    period: j['period']?.toString() ?? '',
    startDate: j['start_date']?.toString(), endDate: j['end_date']?.toString(),
    createdAt: j['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId, 'title': title, 'goal_type': goalType,
    'period': period, 'current_value': currentValue, 'weight': weight,
    if (parentGoalId != null) 'parent_goal_id': parentGoalId,
    if (description  != null) 'description':    description,
    if (targetValue  != null) 'target_value':   targetValue,
    if (unit         != null) 'unit':           unit,
    if (startDate    != null) 'start_date':     startDate,
    if (endDate      != null) 'end_date':       endDate,
  };
}

class Review360 {
  final String? id;
  final String employeeId;
  final String reviewerId;
  final String reviewType;
  final String reviewPeriod;
  final int rating;
  final String? strengths;
  final String? areasForImprovement;
  final String? comments;
  final bool isAnonymous;
  final String status;
  final String? createdAt;

  Review360({
    this.id, required this.employeeId, required this.reviewerId,
    required this.reviewType, required this.reviewPeriod, required this.rating,
    this.strengths, this.areasForImprovement, this.comments,
    this.isAnonymous = false, this.status = 'SUBMITTED', this.createdAt,
  });

  factory Review360.fromJson(Map<String, dynamic> j) => Review360(
    id: j['id']?.toString(), employeeId: j['employee_id']?.toString() ?? '',
    reviewerId: j['reviewer_id']?.toString() ?? '',
    reviewType: j['review_type']?.toString() ?? 'PEER',
    reviewPeriod: j['review_period']?.toString() ?? '',
    rating: (j['rating'] as num?)?.toInt() ?? 1,
    strengths: j['strengths']?.toString(),
    areasForImprovement: j['areas_for_improvement']?.toString(),
    comments: j['comments']?.toString(),
    isAnonymous: j['is_anonymous'] as bool? ?? false,
    status: j['status']?.toString() ?? 'SUBMITTED',
    createdAt: j['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId, 'review_type': reviewType,
    'review_period': reviewPeriod, 'rating': rating, 'is_anonymous': isAnonymous,
    if (strengths           != null) 'strengths':             strengths,
    if (areasForImprovement != null) 'areas_for_improvement': areasForImprovement,
    if (comments            != null) 'comments':              comments,
  };
}

class PIPMilestone {
  final String? id;
  final String pipId;
  final String milestoneDate;
  final String description;
  final bool? met;
  final String? notes;

  PIPMilestone({
    this.id, required this.pipId, required this.milestoneDate,
    required this.description, this.met, this.notes,
  });

  factory PIPMilestone.fromJson(Map<String, dynamic> j) => PIPMilestone(
    id: j['id']?.toString(), pipId: j['pip_id']?.toString() ?? '',
    milestoneDate: j['milestone_date']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    met: j['met'] as bool?, notes: j['notes']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'milestone_date': milestoneDate, 'description': description,
    if (met   != null) 'met':   met,
    if (notes != null) 'notes': notes,
  };
}

class PIP {
  final String? id;
  final String employeeId;
  final String title;
  final String reason;
  final String objectives;
  final String? supportProvided;
  final String startDate;
  final String endDate;
  final String reviewFrequency;
  final String status;
  final String? outcomeSummary;
  final int? outcomeRating;
  final String? createdAt;
  final List<PIPMilestone> milestones;

  PIP({
    this.id, required this.employeeId, required this.title,
    required this.reason, required this.objectives, this.supportProvided,
    required this.startDate, required this.endDate,
    this.reviewFrequency = 'WEEKLY', this.status = 'ACTIVE',
    this.outcomeSummary, this.outcomeRating, this.createdAt,
    this.milestones = const [],
  });

  factory PIP.fromJson(Map<String, dynamic> j) => PIP(
    id: j['id']?.toString(), employeeId: j['employee_id']?.toString() ?? '',
    title: j['title']?.toString() ?? '', reason: j['reason']?.toString() ?? '',
    objectives: j['objectives']?.toString() ?? '',
    supportProvided: j['support_provided']?.toString(),
    startDate: j['start_date']?.toString() ?? '',
    endDate: j['end_date']?.toString() ?? '',
    reviewFrequency: j['review_frequency']?.toString() ?? 'WEEKLY',
    status: j['status']?.toString() ?? 'ACTIVE',
    outcomeSummary: j['outcome_summary']?.toString(),
    outcomeRating: (j['outcome_rating'] as num?)?.toInt(),
    createdAt: j['created_at']?.toString(),
    milestones: (j['milestones'] as List? ?? [])
        .map((m) => PIPMilestone.fromJson(m)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId, 'title': title, 'reason': reason,
    'objectives': objectives, 'start_date': startDate, 'end_date': endDate,
    'review_frequency': reviewFrequency,
    if (supportProvided != null) 'support_provided': supportProvided,
  };
}
