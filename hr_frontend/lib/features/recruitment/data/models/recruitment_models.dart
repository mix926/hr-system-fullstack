// lib/features/recruitment/data/models/recruitment_models.dart

class JobPosting {
  final String? id;
  final String title;
  final String? departmentId;
  final String description;
  final String? requirements;
  final String? responsibilities;
  final String jobType;       // FULL_TIME | PART_TIME | CONTRACT | INTERNSHIP
  final String? location;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCurrency;
  final String status;        // DRAFT | OPEN | PAUSED | CLOSED | FILLED
  final String? closingDate;
  final int vacancies;
  final int filled;
  final bool isPublic;
  final String? postedBy;
  final String? postedDate;
  final String? createdAt;

  JobPosting({
    this.id,
    required this.title,
    this.departmentId,
    required this.description,
    this.requirements,
    this.responsibilities,
    this.jobType = 'FULL_TIME',
    this.location,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'USD',
    this.status = 'DRAFT',
    this.closingDate,
    this.vacancies = 1,
    this.filled = 0,
    this.isPublic = true,
    this.postedBy,
    this.postedDate,
    this.createdAt,
  });

  factory JobPosting.fromJson(Map<String, dynamic> j) => JobPosting(
    id:               j['id']?.toString(),
    title:            j['title']?.toString() ?? '',
    departmentId:     j['department_id']?.toString(),
    description:      j['description']?.toString() ?? '',
    requirements:     j['requirements']?.toString(),
    responsibilities: j['responsibilities']?.toString(),
    jobType:          j['job_type']?.toString() ?? 'FULL_TIME',
    location:         j['location']?.toString(),
    salaryMin:        (j['salary_min'] as num?)?.toDouble(),
    salaryMax:        (j['salary_max'] as num?)?.toDouble(),
    salaryCurrency:   j['salary_currency']?.toString() ?? 'USD',
    status:           j['status']?.toString() ?? 'DRAFT',
    closingDate:      j['closing_date']?.toString(),
    vacancies:        (j['vacancies'] as num?)?.toInt() ?? 1,
    filled:           (j['filled'] as num?)?.toInt() ?? 0,
    isPublic:         j['is_public'] as bool? ?? true,
    postedBy:         j['posted_by']?.toString(),
    postedDate:       j['posted_date']?.toString(),
    createdAt:        j['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'title':            title,
    'description':      description,
    'job_type':         jobType,
    'vacancies':        vacancies,
    'is_public':        isPublic,
    'salary_currency':  salaryCurrency,
    if (departmentId     != null) 'department_id':    departmentId,
    if (requirements     != null) 'requirements':     requirements,
    if (responsibilities != null) 'responsibilities': responsibilities,
    if (location         != null) 'location':         location,
    if (salaryMin        != null) 'salary_min':       salaryMin,
    if (salaryMax        != null) 'salary_max':       salaryMax,
    if (closingDate      != null) 'closing_date':     closingDate,
  };
}

class Candidate {
  final String? id;
  final String jobPostingId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? linkedinUrl;
  final String? resumePath;
  final String? coverLetter;
  final String? currentPosition;
  final int? yearsOfExperience;
  final double? expectedSalary;
  final String stage;  // APPLIED|SCREENING|INTERVIEW|OFFER|HIRED|REJECTED|WITHDRAWN
  final String? source;
  final int? rating;
  final String? notes;
  final String? appliedAt;

  Candidate({
    this.id,
    required this.jobPostingId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.linkedinUrl,
    this.resumePath,
    this.coverLetter,
    this.currentPosition,
    this.yearsOfExperience,
    this.expectedSalary,
    this.stage = 'APPLIED',
    this.source,
    this.rating,
    this.notes,
    this.appliedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Candidate.fromJson(Map<String, dynamic> j) => Candidate(
    id:                  j['id']?.toString(),
    jobPostingId:        j['job_posting_id']?.toString() ?? '',
    firstName:           j['first_name']?.toString() ?? '',
    lastName:            j['last_name']?.toString() ?? '',
    email:               j['email']?.toString() ?? '',
    phone:               j['phone']?.toString(),
    linkedinUrl:         j['linkedin_url']?.toString(),
    resumePath:          j['resume_path']?.toString(),
    coverLetter:         j['cover_letter']?.toString(),
    currentPosition:     j['current_position']?.toString(),
    yearsOfExperience:   (j['years_of_experience'] as num?)?.toInt(),
    expectedSalary:      (j['expected_salary'] as num?)?.toDouble(),
    stage:               j['stage']?.toString() ?? 'APPLIED',
    source:              j['source']?.toString(),
    rating:              (j['rating'] as num?)?.toInt(),
    notes:               j['notes']?.toString(),
    appliedAt:           j['applied_at']?.toString(),
  );
}

class Interview {
  final String? id;
  final String candidateId;
  final String jobPostingId;
  final int interviewRound;
  final String? interviewType;
  final String scheduledAt;
  final int durationMinutes;
  final String? location;
  final String mode;           // ONSITE | VIDEO | PHONE
  final String? interviewerId;
  final String status;         // SCHEDULED | COMPLETED | CANCELLED | NO_SHOW
  final String? feedback;
  final int? rating;
  final String? recommendation;
  final String? createdAt;

  Interview({
    this.id,
    required this.candidateId,
    required this.jobPostingId,
    this.interviewRound = 1,
    this.interviewType,
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.location,
    this.mode = 'ONSITE',
    this.interviewerId,
    this.status = 'SCHEDULED',
    this.feedback,
    this.rating,
    this.recommendation,
    this.createdAt,
  });

  factory Interview.fromJson(Map<String, dynamic> j) => Interview(
    id:              j['id']?.toString(),
    candidateId:     j['candidate_id']?.toString() ?? '',
    jobPostingId:    j['job_posting_id']?.toString() ?? '',
    interviewRound:  (j['interview_round'] as num?)?.toInt() ?? 1,
    interviewType:   j['interview_type']?.toString(),
    scheduledAt:     j['scheduled_at']?.toString() ?? '',
    durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 60,
    location:        j['location']?.toString(),
    mode:            j['mode']?.toString() ?? 'ONSITE',
    interviewerId:   j['interviewer_id']?.toString(),
    status:          j['status']?.toString() ?? 'SCHEDULED',
    feedback:        j['feedback']?.toString(),
    rating:          (j['rating'] as num?)?.toInt(),
    recommendation:  j['recommendation']?.toString(),
    createdAt:       j['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'candidate_id':    candidateId,
    'job_posting_id':  jobPostingId,
    'interview_round': interviewRound,
    'scheduled_at':    scheduledAt,
    'duration_minutes': durationMinutes,
    'mode':            mode,
    if (interviewType != null) 'interview_type': interviewType,
    if (location      != null) 'location':       location,
    if (interviewerId != null) 'interviewer_id': interviewerId,
  };
}

class OfferLetter {
  final String? id;
  final String candidateId;
  final String jobPostingId;
  final double proposedSalary;
  final String salaryCurrency;
  final String jobTitle;
  final String startDate;
  final String? offerExpiryDate;
  final String? benefitsSummary;
  final String status;  // PENDING | ACCEPTED | DECLINED | EXPIRED | WITHDRAWN
  final String? offeredBy;
  final String? offeredAt;

  OfferLetter({
    this.id,
    required this.candidateId,
    required this.jobPostingId,
    required this.proposedSalary,
    this.salaryCurrency = 'USD',
    required this.jobTitle,
    required this.startDate,
    this.offerExpiryDate,
    this.benefitsSummary,
    this.status = 'PENDING',
    this.offeredBy,
    this.offeredAt,
  });

  factory OfferLetter.fromJson(Map<String, dynamic> j) => OfferLetter(
    id:               j['id']?.toString(),
    candidateId:      j['candidate_id']?.toString() ?? '',
    jobPostingId:     j['job_posting_id']?.toString() ?? '',
    proposedSalary:   (j['proposed_salary'] as num?)?.toDouble() ?? 0,
    salaryCurrency:   j['salary_currency']?.toString() ?? 'USD',
    jobTitle:         j['job_title']?.toString() ?? '',
    startDate:        j['start_date']?.toString() ?? '',
    offerExpiryDate:  j['offer_expiry_date']?.toString(),
    benefitsSummary:  j['benefits_summary']?.toString(),
    status:           j['status']?.toString() ?? 'PENDING',
    offeredBy:        j['offered_by']?.toString(),
    offeredAt:        j['offered_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'candidate_id':    candidateId,
    'job_posting_id':  jobPostingId,
    'proposed_salary': proposedSalary,
    'salary_currency': salaryCurrency,
    'job_title':       jobTitle,
    'start_date':      startDate,
    if (offerExpiryDate  != null) 'offer_expiry_date':  offerExpiryDate,
    if (benefitsSummary  != null) 'benefits_summary':   benefitsSummary,
  };
}

class PipelineSummary {
  final String jobPostingId;
  final String jobTitle;
  final int totalCandidates;
  final int applied;
  final int screening;
  final int interview;
  final int offer;
  final int hired;
  final int rejected;
  final int withdrawn;

  PipelineSummary({
    required this.jobPostingId,
    required this.jobTitle,
    required this.totalCandidates,
    required this.applied,
    required this.screening,
    required this.interview,
    required this.offer,
    required this.hired,
    required this.rejected,
    required this.withdrawn,
  });

  factory PipelineSummary.fromJson(Map<String, dynamic> j) => PipelineSummary(
    jobPostingId:    j['job_posting_id']?.toString() ?? '',
    jobTitle:        j['job_title']?.toString() ?? '',
    totalCandidates: (j['total_candidates'] as num?)?.toInt() ?? 0,
    applied:         (j['applied']     as num?)?.toInt() ?? 0,
    screening:       (j['screening']   as num?)?.toInt() ?? 0,
    interview:       (j['interview']   as num?)?.toInt() ?? 0,
    offer:           (j['offer']       as num?)?.toInt() ?? 0,
    hired:           (j['hired']       as num?)?.toInt() ?? 0,
    rejected:        (j['rejected']    as num?)?.toInt() ?? 0,
    withdrawn:       (j['withdrawn']   as num?)?.toInt() ?? 0,
  );
}
