"""
Recruitment (ATS) API:

- Job posting CRUD + public career page listing
- Candidate pipeline: apply, list by stage, move stages
- Interview scheduling with feedback submission
- Offer letter management with accept/decline
- Pipeline summary dashboard
"""
from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
import os
import uuid

from app.core.database import get_db
from app.models.models import Employee, RoleEnum
from app.models.recruitment import (
    JobPosting,
    Candidate,
    InterviewSchedule,
    OfferLetter,
    JobStatus,
    JobType,
    CandidateStage,
    InterviewStatus,
    OfferStatus,
)
from app.schemas.recruitment import (
    JobPostingCreate,
    JobPostingUpdate,
    JobPostingResponse,
    CandidateApply,
    CandidateCreate,
    CandidateUpdate,
    CandidateResponse,
    CandidateStageUpdate,
    InterviewCreate,
    InterviewUpdate,
    InterviewFeedback,
    InterviewResponse,
    OfferLetterCreate,
    OfferLetterUpdate,
    OfferLetterResponse,
    PipelineSummary,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/recruitment", tags=["Recruitment (ATS)"])

# ── Helpers ────────────────────────────────────────────────────

def _role(user) -> str:
    return user.role.value if hasattr(user.role, "value") else user.role


def _require_admin_or_manager(user):
    role = _role(user)
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can perform this action",
        )


def _require_admin(user):
    if _role(user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can perform this action",
        )


# Directory for resume uploads
RESUME_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads", "resumes")
os.makedirs(RESUME_DIR, exist_ok=True)


# ─── Job Posting Endpoints ─────────────────────────────────────

@router.get("/jobs", response_model=List[JobPostingResponse])
def get_job_postings(
    status_filter: Optional[str] = None,
    public_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List job postings. Optionally filter by status or public visibility."""
    query = db.query(JobPosting)
    if status_filter:
        try:
            query = query.filter(JobPosting.status == JobStatus(status_filter))
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid status filter")
    if public_only:
        query = query.filter(JobPosting.is_public == True, JobPosting.status == JobStatus.OPEN)
    return query.order_by(JobPosting.created_at.desc()).all()


@router.get("/jobs/public", response_model=List[JobPostingResponse])
def get_public_job_postings(db: Session = Depends(get_db)):
    """Public endpoint — list open job postings for career page. No auth required."""
    return db.query(JobPosting).filter(
        JobPosting.is_public == True,
        JobPosting.status == JobStatus.OPEN,
    ).order_by(JobPosting.created_at.desc()).all()


@router.get("/jobs/{job_id}", response_model=JobPostingResponse)
def get_job_posting(
    job_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    job = db.query(JobPosting).filter(JobPosting.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job posting not found")
    return job


@router.post("/jobs", response_model=JobPostingResponse, status_code=status.HTTP_201_CREATED)
def create_job_posting(
    body: JobPostingCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new job posting. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    job = JobPosting(
        **body.model_dump(),
        posted_by=current_user.id,
        posted_date=datetime.utcnow(),
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


@router.patch("/jobs/{job_id}", response_model=JobPostingResponse)
def update_job_posting(
    job_id: str,
    body: JobPostingUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a job posting. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    job = db.query(JobPosting).filter(JobPosting.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job posting not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(job, key, value)
    db.commit()
    db.refresh(job)
    return job


@router.delete("/jobs/{job_id}")
def delete_job_posting(
    job_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a job posting. ADMIN only."""
    _require_admin(current_user)
    job = db.query(JobPosting).filter(JobPosting.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job posting not found")
    db.delete(job)
    db.commit()
    return {"message": "Job posting deleted"}


# ─── Candidate Pipeline ───────────────────────────────────────

@router.post("/jobs/{job_id}/apply", response_model=CandidateResponse, status_code=status.HTTP_201_CREATED)
async def apply_for_job(
    job_id: str,
    first_name: str = Form(...),
    last_name: str = Form(...),
    email: str = Form(...),
    phone: Optional[str] = Form(None),
    linkedin_url: Optional[str] = Form(None),
    cover_letter: Optional[str] = Form(None),
    current_position: Optional[str] = Form(None),
    years_of_experience: Optional[int] = Form(None),
    expected_salary: Optional[float] = Form(None),
    source: Optional[str] = Form(None),
    resume: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
):
    """Public endpoint — apply for a job. No auth required.
    
    Accepts multipart form data with optional resume upload.
    """
    job = db.query(JobPosting).filter(JobPosting.id == job_id, JobPosting.status == JobStatus.OPEN).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job posting not found or closed")

    # Save resume if provided
    resume_path = None
    if resume:
        file_ext = os.path.splitext(resume.filename)[1]
        saved_name = f"{uuid.uuid4()}{file_ext}"
        resume_path = os.path.join(RESUME_DIR, saved_name)
        content = await resume.read()
        with open(resume_path, "wb") as f:
            f.write(content)

    candidate = Candidate(
        job_posting_id=job_id,
        first_name=first_name,
        last_name=last_name,
        email=email,
        phone=phone,
        linkedin_url=linkedin_url,
        cover_letter=cover_letter,
        current_position=current_position,
        years_of_experience=years_of_experience,
        expected_salary=expected_salary,
        source=source or "Career Page",
        resume_path=resume_path,
        stage=CandidateStage.APPLIED,
    )
    db.add(candidate)
    db.commit()
    db.refresh(candidate)
    return candidate


@router.post("/candidates", response_model=CandidateResponse, status_code=status.HTTP_201_CREATED)
def add_candidate(
    body: CandidateCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Recruiser manually adds a candidate. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    job = db.query(JobPosting).filter(JobPosting.id == body.job_posting_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job posting not found")
    candidate = Candidate(
        **body.model_dump(),
        stage=CandidateStage.APPLIED,
    )
    db.add(candidate)
    db.commit()
    db.refresh(candidate)
    return candidate


@router.get("/jobs/{job_id}/candidates", response_model=List[CandidateResponse])
def get_job_candidates(
    job_id: str,
    stage: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List candidates for a job posting. Optionally filter by pipeline stage. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    query = db.query(Candidate).filter(Candidate.job_posting_id == job_id)
    if stage:
        try:
            query = query.filter(Candidate.stage == CandidateStage(stage))
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid stage")
    return query.order_by(Candidate.applied_at.desc()).all()


@router.patch("/candidates/{candidate_id}/stage", response_model=CandidateResponse)
def update_candidate_stage(
    candidate_id: str,
    body: CandidateStageUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Move a candidate to a new pipeline stage. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    if not candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")
    candidate.stage = body.stage
    candidate.stage_updated_at = datetime.utcnow()

    # If hired, could create employee record (manual step for now)
    if body.stage == CandidateStage.HIRED:
        candidate.job_posting.filled += 1
        if candidate.job_posting.filled >= candidate.job_posting.vacancies:
            candidate.job_posting.status = JobStatus.FILLED

    db.commit()
    db.refresh(candidate)
    return candidate


@router.patch("/candidates/{candidate_id}", response_model=CandidateResponse)
def update_candidate(
    candidate_id: str,
    body: CandidateUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update candidate info. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    if not candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(candidate, key, value)
    db.commit()
    db.refresh(candidate)
    return candidate


@router.delete("/candidates/{candidate_id}")
def delete_candidate(
    candidate_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a candidate. ADMIN only."""
    _require_admin(current_user)
    candidate = db.query(Candidate).filter(Candidate.id == candidate_id).first()
    if not candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")
    db.delete(candidate)
    db.commit()
    return {"message": "Candidate deleted"}


# ─── Interview Scheduling ──────────────────────────────────────

@router.post("/interviews", response_model=InterviewResponse, status_code=status.HTTP_201_CREATED)
def schedule_interview(
    body: InterviewCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Schedule an interview. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    candidate = db.query(Candidate).filter(Candidate.id == body.candidate_id).first()
    if not candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")
    interview = InterviewSchedule(**body.model_dump(), status=InterviewStatus.SCHEDULED)
    db.add(interview)
    db.commit()
    db.refresh(interview)
    return interview


@router.get("/interviews", response_model=List[InterviewResponse])
def get_interviews(
    candidate_id: Optional[str] = None,
    job_posting_id: Optional[str] = None,
    upcoming_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List interviews. Optionally filter by candidate or job. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    query = db.query(InterviewSchedule)
    if candidate_id:
        query = query.filter(InterviewSchedule.candidate_id == candidate_id)
    if job_posting_id:
        query = query.filter(InterviewSchedule.job_posting_id == job_posting_id)
    if upcoming_only:
        query = query.filter(InterviewSchedule.scheduled_at >= datetime.utcnow())
    return query.order_by(InterviewSchedule.scheduled_at.desc()).all()


@router.patch("/interviews/{interview_id}", response_model=InterviewResponse)
def update_interview(
    interview_id: str,
    body: InterviewUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update interview schedule or status. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    interview = db.query(InterviewSchedule).filter(InterviewSchedule.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(interview, key, value)
    db.commit()
    db.refresh(interview)
    return interview


@router.patch("/interviews/{interview_id}/feedback", response_model=InterviewResponse)
def submit_interview_feedback(
    interview_id: str,
    body: InterviewFeedback,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Submit feedback for a completed interview. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    interview = db.query(InterviewSchedule).filter(InterviewSchedule.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")
    interview.feedback = body.feedback
    interview.rating = body.rating
    interview.recommendation = body.recommendation
    if body.status:
        interview.status = body.status
    elif not interview.status or interview.status == InterviewStatus.SCHEDULED:
        interview.status = InterviewStatus.COMPLETED
    db.commit()
    db.refresh(interview)
    return interview


@router.delete("/interviews/{interview_id}")
def delete_interview(
    interview_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete an interview. ADMIN only."""
    _require_admin(current_user)
    interview = db.query(InterviewSchedule).filter(InterviewSchedule.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")
    db.delete(interview)
    db.commit()
    return {"message": "Interview deleted"}


# ─── Offer Letter Management ───────────────────────────────────

@router.post("/offers", response_model=OfferLetterResponse, status_code=status.HTTP_201_CREATED)
def create_offer(
    body: OfferLetterCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create an offer letter. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    candidate = db.query(Candidate).filter(Candidate.id == body.candidate_id).first()
    if not candidate:
        raise HTTPException(status_code=404, detail="Candidate not found")
    offer = OfferLetter(
        **body.model_dump(),
        offered_by=current_user.id,
        status=OfferStatus.PENDING,
    )
    db.add(offer)
    # Move candidate to OFFER stage
    candidate.stage = CandidateStage.OFFER
    candidate.stage_updated_at = datetime.utcnow()
    db.commit()
    db.refresh(offer)
    return offer


@router.get("/offers", response_model=List[OfferLetterResponse])
def get_offers(
    candidate_id: Optional[str] = None,
    status_filter: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List offer letters. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    query = db.query(OfferLetter)
    if candidate_id:
        query = query.filter(OfferLetter.candidate_id == candidate_id)
    if status_filter:
        try:
            query = query.filter(OfferLetter.status == OfferStatus(status_filter))
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid status filter")
    return query.order_by(OfferLetter.offered_at.desc()).all()


@router.get("/offers/{offer_id}", response_model=OfferLetterResponse)
def get_offer(
    offer_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    offer = db.query(OfferLetter).filter(OfferLetter.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    return offer


@router.patch("/offers/{offer_id}", response_model=OfferLetterResponse)
def update_offer(
    offer_id: str,
    body: OfferLetterUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update an offer letter. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    offer = db.query(OfferLetter).filter(OfferLetter.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(offer, key, value)
    if body.status:
        offer.responded_at = datetime.utcnow()
        # Update candidate stage based on offer response
        candidate = offer.candidate
        if body.status == OfferStatus.ACCEPTED:
            candidate.stage = CandidateStage.HIRED
        elif body.status == OfferStatus.DECLINED:
            candidate.stage = CandidateStage.REJECTED
    db.commit()
    db.refresh(offer)
    return offer


@router.delete("/offers/{offer_id}")
def delete_offer(
    offer_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete an offer. ADMIN only."""
    _require_admin(current_user)
    offer = db.query(OfferLetter).filter(OfferLetter.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    db.delete(offer)
    db.commit()
    return {"message": "Offer deleted"}


# ─── Pipeline Summary ─────────────────────────────────────────

@router.get("/jobs/{job_id}/pipeline", response_model=PipelineSummary)
def get_pipeline_summary(
    job_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get candidate pipeline summary for a job posting. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    job = db.query(JobPosting).filter(JobPosting.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job posting not found")
    candidates = db.query(Candidate).filter(Candidate.job_posting_id == job_id).all()
    return PipelineSummary(
        job_posting_id=job_id,
        job_title=job.title,
        total_candidates=len(candidates),
        applied=sum(1 for c in candidates if c.stage == CandidateStage.APPLIED),
        screening=sum(1 for c in candidates if c.stage == CandidateStage.SCREENING),
        interview=sum(1 for c in candidates if c.stage == CandidateStage.INTERVIEW),
        offer=sum(1 for c in candidates if c.stage == CandidateStage.OFFER),
        hired=sum(1 for c in candidates if c.stage == CandidateStage.HIRED),
        rejected=sum(1 for c in candidates if c.stage == CandidateStage.REJECTED),
        withdrawn=sum(1 for c in candidates if c.stage == CandidateStage.WITHDRAWN),
    )
