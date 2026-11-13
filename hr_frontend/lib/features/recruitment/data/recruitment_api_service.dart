// lib/features/recruitment/data/recruitment_api_service.dart

import 'package:dio/dio.dart';
import '../../../core/errors/result.dart';
import '../../../core/utils/constants.dart';
import 'models/recruitment_models.dart';

class RecruitmentApiService {
  final Dio _dio;
  RecruitmentApiService(this._dio);

  String _detail(DioException e, String fb) {
    final d = e.response?.data;
    if (d is Map<String, dynamic>) return d['detail']?.toString() ?? fb;
    if (d is String && d.isNotEmpty) return d;
    return fb;
  }

  // ── Job Postings ──────────────────────────────────────────────

  Future<Result<List<JobPosting>>> getJobs({String? status}) async {
    try {
      final r = await _dio.get(AppConstants.jobsEndpoint,
          queryParameters: status != null ? {'status_filter': status} : null);
      return Result.success((r.data as List).map((j) => JobPosting.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load jobs')));
    }
  }

  Future<Result<JobPosting>> getJobById(String id) async {
    try {
      final r = await _dio.get(AppConstants.jobByIdEndpoint(id));
      return Result.success(JobPosting.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Job not found')));
    }
  }

  Future<Result<JobPosting>> createJob(JobPosting job) async {
    try {
      final r = await _dio.post(AppConstants.jobsEndpoint, data: job.toJson());
      return Result.success(JobPosting.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create job')));
    }
  }

  Future<Result<JobPosting>> updateJob(String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch(AppConstants.jobByIdEndpoint(id), data: updates);
      return Result.success(JobPosting.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update job')));
    }
  }

  Future<Result<void>> deleteJob(String id) async {
    try {
      await _dio.delete(AppConstants.jobByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete job')));
    }
  }

  // ── Candidates ────────────────────────────────────────────────

  Future<Result<List<Candidate>>> getCandidates(String jobId, {String? stage}) async {
    try {
      final r = await _dio.get(AppConstants.jobCandidatesEndpoint(jobId),
          queryParameters: stage != null ? {'stage': stage} : null);
      return Result.success((r.data as List).map((j) => Candidate.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load candidates')));
    }
  }

  Future<Result<Candidate>> createCandidate(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post(AppConstants.candidatesEndpoint, data: data);
      return Result.success(Candidate.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to add candidate')));
    }
  }

  Future<Result<Candidate>> updateCandidateStage(String id, String stage) async {
    try {
      final r = await _dio.patch(AppConstants.candidateStageEndpoint(id), data: {'stage': stage});
      return Result.success(Candidate.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update stage')));
    }
  }

  Future<Result<Candidate>> updateCandidate(String id, Map<String, dynamic> updates) async {
    try {
      final r = await _dio.patch(AppConstants.candidateByIdEndpoint(id), data: updates);
      return Result.success(Candidate.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update candidate')));
    }
  }

  Future<Result<void>> deleteCandidate(String id) async {
    try {
      await _dio.delete(AppConstants.candidateByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete candidate')));
    }
  }

  Future<Result<Candidate>> getCandidateById(String id) async {
    try {
      final r = await _dio.get(AppConstants.candidateByIdEndpoint(id));
      return Result.success(Candidate.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Candidate not found')));
    }
  }

  // ── Interviews ────────────────────────────────────────────────

  Future<Result<List<Interview>>> getInterviews({String? candidateId, bool upcomingOnly = false}) async {
    try {
      final r = await _dio.get(AppConstants.interviewsEndpoint, queryParameters: {
        if (candidateId   != null) 'candidate_id':  candidateId,
        if (upcomingOnly) 'upcoming_only': true,
      });
      return Result.success((r.data as List).map((j) => Interview.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load interviews')));
    }
  }

  Future<Result<Interview>> scheduleInterview(Interview interview) async {
    try {
      final r = await _dio.post(AppConstants.interviewsEndpoint, data: interview.toJson());
      return Result.success(Interview.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to schedule interview')));
    }
  }

  Future<Result<Interview>> submitFeedback(
      String id, {String? feedback, int? rating, String? recommendation, String? status}) async {
    try {
      final r = await _dio.patch(AppConstants.interviewFeedbackEndpoint(id), data: {
        if (feedback       != null) 'feedback':       feedback,
        if (rating         != null) 'rating':         rating,
        if (recommendation != null) 'recommendation': recommendation,
        if (status         != null) 'status':         status,
      });
      return Result.success(Interview.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to submit feedback')));
    }
  }

  Future<Result<void>> deleteInterview(String id) async {
    try {
      await _dio.delete(AppConstants.interviewByIdEndpoint(id));
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to delete interview')));
    }
  }

  // ── Offers ────────────────────────────────────────────────────

  Future<Result<List<OfferLetter>>> getOffers({String? candidateId}) async {
    try {
      final r = await _dio.get(AppConstants.offersEndpoint,
          queryParameters: candidateId != null ? {'candidate_id': candidateId} : null);
      return Result.success((r.data as List).map((j) => OfferLetter.fromJson(j)).toList());
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load offers')));
    }
  }

  Future<Result<OfferLetter>> getOfferById(String id) async {
    try {
      final r = await _dio.get(AppConstants.offerByIdEndpoint(id));
      return Result.success(OfferLetter.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Offer not found')));
    }
  }

  Future<Result<OfferLetter>> createOffer(OfferLetter offer) async {
    try {
      final r = await _dio.post(AppConstants.offersEndpoint, data: offer.toJson());
      return Result.success(OfferLetter.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to create offer')));
    }
  }

  Future<Result<OfferLetter>> updateOfferStatus(String id, String status) async {
    try {
      final r = await _dio.patch(AppConstants.offerByIdEndpoint(id), data: {'status': status});
      return Result.success(OfferLetter.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to update offer')));
    }
  }

  // ── Pipeline Summary ──────────────────────────────────────────

  Future<Result<PipelineSummary>> getPipelineSummary(String jobId) async {
    try {
      final r = await _dio.get(AppConstants.jobPipelineEndpoint(jobId));
      return Result.success(PipelineSummary.fromJson(r.data));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: _detail(e, 'Failed to load pipeline')));
    }
  }
}
