"""
Recruitment (ATS) Pydantic schemas:
- JobPosting CRUD
- Candidate pipeline management
- Interview scheduling and feedback
- Offer letter management
"""
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field, EmailStr
from app.models.recruitment import (
    JobStatus,
    JobType,
    CandidateStage,
    InterviewStatus,
    OfferStatus,
)


# ─── Job Posting Schemas ───────────────────────────────────────

class JobPostingBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    department_id: Optional[str] = None
    designation_id: Optional[str] = None
    description: str = Field(..., min_length=1)
    requirements: Optional[str] = None
    responsibilities: Optional[str] = None
    job_type: JobType = JobType.FULL_TIME
    location: Optional[str] = None
    salary_min: Optional[float] = None
    salary_max: Optional[float] = None
    salary_currency: str = "USD"
    closing_date: Optional[date] = None
    vacancies: int = Field(1, ge=1)
    is_public: bool = True


class JobPostingCreate(JobPostingBase):
    pass


class JobPostingUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    department_id: Optional[str] = None
    designation_id: Optional[str] = None
    description: Optional[str] = None
    requirements: Optional[str] = None
    responsibilities: Optional[str] = None
    job_type: Optional[JobType] = None
    location: Optional[str] = None
    salary_min: Optional[float] = None
    salary_max: Optional[float] = None
    salary_currency: Optional[str] = None
    status: Optional[JobStatus] = None
    closing_date: Optional[date] = None
    vacancies: Optional[int] = Field(None, ge=1)
    is_public: Optional[bool] = None


class JobPostingResponse(JobPostingBase):
    id: str
    status: JobStatus
    posted_by: Optional[str] = None
    posted_date: Optional[datetime] = None
    filled: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Candidate Schemas ─────────────────────────────────────────

class CandidateBase(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    email: EmailStr
    phone: Optional[str] = None
    linkedin_url: Optional[str] = None
    resume_path: Optional[str] = None
    cover_letter: Optional[str] = None
    current_position: Optional[str] = None
    years_of_experience: Optional[int] = None
    expected_salary: Optional[float] = None
    source: Optional[str] = None


class CandidateApply(CandidateBase):
    """Public application — no auth required."""
    pass


class CandidateCreate(CandidateBase):
    """Recruiter adds a candidate to a specific job."""
    job_posting_id: str
    notes: Optional[str] = None
    rating: Optional[int] = Field(None, ge=1, le=5)


class CandidateUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    linkedin_url: Optional[str] = None
    resume_path: Optional[str] = None
    cover_letter: Optional[str] = None
    current_position: Optional[str] = None
    years_of_experience: Optional[int] = None
    expected_salary: Optional[float] = None
    source: Optional[str] = None
    notes: Optional[str] = None
    rating: Optional[int] = Field(None, ge=1, le=5)


class CandidateResponse(CandidateBase):
    id: str
    job_posting_id: str
    stage: CandidateStage
    rating: Optional[int] = None
    employee_id: Optional[str] = None
    applied_at: datetime
    stage_updated_at: Optional[datetime] = None
    notes: Optional[str] = None

    class Config:
        from_attributes = True


class CandidateStageUpdate(BaseModel):
    """Move a candidate through the pipeline."""
    stage: CandidateStage


# ─── Interview Schemas ─────────────────────────────────────────

class InterviewBase(BaseModel):
    candidate_id: str
    job_posting_id: str
    interview_round: int = Field(1, ge=1)
    interview_type: Optional[str] = None
    scheduled_at: datetime
    duration_minutes: int = Field(60, ge=1)
    location: Optional[str] = None
    mode: str = "ONSITE"
    interviewer_id: Optional[str] = None


class InterviewCreate(InterviewBase):
    pass


class InterviewUpdate(BaseModel):
    scheduled_at: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, ge=1)
    location: Optional[str] = None
    mode: Optional[str] = None
    interviewer_id: Optional[str] = None
    status: Optional[InterviewStatus] = None


class InterviewFeedback(BaseModel):
    """Submit feedback after an interview."""
    feedback: Optional[str] = None
    rating: Optional[int] = Field(None, ge=1, le=5)
    recommendation: Optional[str] = None  # "HIRE", "NO_HIRE", "STRONG_HIRE"
    status: Optional[InterviewStatus] = None


class InterviewResponse(InterviewBase):
    id: str
    status: InterviewStatus
    feedback: Optional[str] = None
    rating: Optional[int] = None
    recommendation: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Offer Letter Schemas ──────────────────────────────────────

class OfferLetterBase(BaseModel):
    candidate_id: str
    job_posting_id: str
    proposed_salary: float = Field(..., ge=0)
    salary_currency: str = "USD"
    job_title: str = Field(..., min_length=1, max_length=200)
    start_date: date
    offer_expiry_date: Optional[date] = None
    benefits_summary: Optional[str] = None
    terms_conditions: Optional[str] = None


class OfferLetterCreate(OfferLetterBase):
    pass


class OfferLetterUpdate(BaseModel):
    proposed_salary: Optional[float] = Field(None, ge=0)
    salary_currency: Optional[str] = None
    job_title: Optional[str] = None
    start_date: Optional[date] = None
    offer_expiry_date: Optional[date] = None
    benefits_summary: Optional[str] = None
    terms_conditions: Optional[str] = None
    status: Optional[OfferStatus] = None


class OfferLetterResponse(OfferLetterBase):
    id: str
    status: OfferStatus
    offered_by: Optional[str] = None
    offered_at: datetime
    responded_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Pipeline Summary ─────────────────────────────────────────

class PipelineSummary(BaseModel):
    """Summary of candidates at each stage for a job posting."""
    job_posting_id: str
    job_title: str
    total_candidates: int
    applied: int
    screening: int
    interview: int
    offer: int
    hired: int
    rejected: int
    withdrawn: int
