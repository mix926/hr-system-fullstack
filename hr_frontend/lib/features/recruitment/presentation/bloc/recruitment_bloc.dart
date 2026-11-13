// lib/features/recruitment/presentation/bloc/recruitment_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/recruitment_api_service.dart';
import '../../data/models/recruitment_models.dart';

// ── Events ────────────────────────────────────────────────────

abstract class RecruitmentEvent {}

class LoadJobsEvent extends RecruitmentEvent {
  final String? statusFilter;
  LoadJobsEvent({this.statusFilter});
}

class LoadJobDetailEvent extends RecruitmentEvent {
  final String jobId;
  LoadJobDetailEvent(this.jobId);
}

class CreateJobEvent extends RecruitmentEvent {
  final JobPosting job;
  CreateJobEvent(this.job);
}

class UpdateJobEvent extends RecruitmentEvent {
  final String jobId;
  final Map<String, dynamic> updates;
  UpdateJobEvent(this.jobId, this.updates);
}

class DeleteJobEvent extends RecruitmentEvent {
  final String jobId;
  DeleteJobEvent(this.jobId);
}

class LoadCandidatesEvent extends RecruitmentEvent {
  final String jobId;
  final String? stage;
  LoadCandidatesEvent(this.jobId, {this.stage});
}

class UpdateCandidateStageEvent extends RecruitmentEvent {
  final String candidateId;
  final String newStage;
  UpdateCandidateStageEvent(this.candidateId, this.newStage);
}

class LoadInterviewsEvent extends RecruitmentEvent {
  final String? candidateId;
  final bool upcomingOnly;
  LoadInterviewsEvent({this.candidateId, this.upcomingOnly = false});
}

class ScheduleInterviewEvent extends RecruitmentEvent {
  final Interview interview;
  ScheduleInterviewEvent(this.interview);
}

class SubmitInterviewFeedbackEvent extends RecruitmentEvent {
  final String interviewId;
  final String? feedback;
  final int? rating;
  final String? recommendation;
  SubmitInterviewFeedbackEvent(this.interviewId,
      {this.feedback, this.rating, this.recommendation});
}

class LoadOffersEvent extends RecruitmentEvent {
  final String? candidateId;
  LoadOffersEvent({this.candidateId});
}

class CreateOfferEvent extends RecruitmentEvent {
  final OfferLetter offer;
  CreateOfferEvent(this.offer);
}

class UpdateOfferStatusEvent extends RecruitmentEvent {
  final String offerId;
  final String status;
  UpdateOfferStatusEvent(this.offerId, this.status);
}

class LoadPipelineEvent extends RecruitmentEvent {
  final String jobId;
  LoadPipelineEvent(this.jobId);
}

// ── States ────────────────────────────────────────────────────

abstract class RecruitmentState {}

class RecruitmentInitial extends RecruitmentState {}
class RecruitmentLoading extends RecruitmentState {}

class JobsLoaded extends RecruitmentState {
  final List<JobPosting> jobs;
  JobsLoaded(this.jobs);
}

class JobDetailLoaded extends RecruitmentState {
  final JobPosting job;
  final List<Candidate> candidates;
  final PipelineSummary? pipeline;
  JobDetailLoaded(this.job, this.candidates, {this.pipeline});
}

class CandidatesLoaded extends RecruitmentState {
  final List<Candidate> candidates;
  CandidatesLoaded(this.candidates);
}

class InterviewsLoaded extends RecruitmentState {
  final List<Interview> interviews;
  InterviewsLoaded(this.interviews);
}

class OffersLoaded extends RecruitmentState {
  final List<OfferLetter> offers;
  OffersLoaded(this.offers);
}

class PipelineLoaded extends RecruitmentState {
  final PipelineSummary summary;
  PipelineLoaded(this.summary);
}

class RecruitmentSuccess extends RecruitmentState {
  final String message;
  RecruitmentSuccess(this.message);
}

class RecruitmentError extends RecruitmentState {
  final String message;
  RecruitmentError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────

class RecruitmentBloc extends Bloc<RecruitmentEvent, RecruitmentState> {
  final RecruitmentApiService _api;

  RecruitmentBloc(this._api) : super(RecruitmentInitial()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<LoadJobDetailEvent>(_onLoadJobDetail);
    on<CreateJobEvent>(_onCreateJob);
    on<UpdateJobEvent>(_onUpdateJob);
    on<DeleteJobEvent>(_onDeleteJob);
    on<LoadCandidatesEvent>(_onLoadCandidates);
    on<UpdateCandidateStageEvent>(_onUpdateCandidateStage);
    on<LoadInterviewsEvent>(_onLoadInterviews);
    on<ScheduleInterviewEvent>(_onScheduleInterview);
    on<SubmitInterviewFeedbackEvent>(_onSubmitFeedback);
    on<LoadOffersEvent>(_onLoadOffers);
    on<CreateOfferEvent>(_onCreateOffer);
    on<UpdateOfferStatusEvent>(_onUpdateOfferStatus);
    on<LoadPipelineEvent>(_onLoadPipeline);
  }

  Future<void> _onLoadJobs(LoadJobsEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.getJobs(status: e.statusFilter);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (jobs) => emit(JobsLoaded(jobs)),
    );
  }

  Future<void> _onLoadJobDetail(LoadJobDetailEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final jobResult = await _api.getJobById(e.jobId);
    jobResult.fold(
      (f) => emit(RecruitmentError(f.message)),
      (job) async {
        final candidatesResult = await _api.getCandidates(e.jobId);
        final pipelineResult   = await _api.getPipelineSummary(e.jobId);
        final candidates = candidatesResult.fold((_) => <Candidate>[], (c) => c);
        final pipeline   = pipelineResult.fold((_) => null, (p) => p);
        emit(JobDetailLoaded(job, candidates, pipeline: pipeline));
      },
    );
  }

  Future<void> _onCreateJob(CreateJobEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.createJob(e.job);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Job posted successfully')),
    );
  }

  Future<void> _onUpdateJob(UpdateJobEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.updateJob(e.jobId, e.updates);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Job updated successfully')),
    );
  }

  Future<void> _onDeleteJob(DeleteJobEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.deleteJob(e.jobId);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Job deleted')),
    );
  }

  Future<void> _onLoadCandidates(LoadCandidatesEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.getCandidates(e.jobId, stage: e.stage);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (c) => emit(CandidatesLoaded(c)),
    );
  }

  Future<void> _onUpdateCandidateStage(UpdateCandidateStageEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.updateCandidateStage(e.candidateId, e.newStage);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Candidate stage updated')),
    );
  }

  Future<void> _onLoadInterviews(LoadInterviewsEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.getInterviews(candidateId: e.candidateId, upcomingOnly: e.upcomingOnly);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (i) => emit(InterviewsLoaded(i)),
    );
  }

  Future<void> _onScheduleInterview(ScheduleInterviewEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.scheduleInterview(e.interview);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Interview scheduled')),
    );
  }

  Future<void> _onSubmitFeedback(SubmitInterviewFeedbackEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.submitFeedback(e.interviewId,
        feedback: e.feedback, rating: e.rating, recommendation: e.recommendation);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Feedback submitted')),
    );
  }

  Future<void> _onLoadOffers(LoadOffersEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.getOffers(candidateId: e.candidateId);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (o) => emit(OffersLoaded(o)),
    );
  }

  Future<void> _onCreateOffer(CreateOfferEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.createOffer(e.offer);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Offer sent')),
    );
  }

  Future<void> _onUpdateOfferStatus(UpdateOfferStatusEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.updateOfferStatus(e.offerId, e.status);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (_) => emit(RecruitmentSuccess('Offer updated')),
    );
  }

  Future<void> _onLoadPipeline(LoadPipelineEvent e, Emitter emit) async {
    emit(RecruitmentLoading());
    final r = await _api.getPipelineSummary(e.jobId);
    r.fold(
      (f) => emit(RecruitmentError(f.message)),
      (p) => emit(PipelineLoaded(p)),
    );
  }
}
