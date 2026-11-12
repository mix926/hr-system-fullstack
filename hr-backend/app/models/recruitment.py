"""
Recruitment (ATS) models:

- JobPosting: open positions with requirements and status tracking
- Candidate: applicant pipeline tracking (applied → screening → interview → offer → hired/rejected)
- InterviewSchedule: interview scheduling with feedback
- OfferLetter: job offers with salary, start date, acceptance tracking
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text, Integer, Float, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class JobStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    OPEN = "OPEN"
    PAUSED = "PAUSED"
    CLOSED = "CLOSED"
    FILLED = "FILLED"


class JobType(str, enum.Enum):
    FULL_TIME = "FULL_TIME"
    PART_TIME = "PART_TIME"
    CONTRACT = "CONTRACT"
    INTERNSHIP = "INTERNSHIP"
    TEMPORARY = "TEMPORARY"


class CandidateStage(str, enum.Enum):
    """Pipeline stages."""
    APPLIED = "APPLIED"
    SCREENING = "SCREENING"
    INTERVIEW = "INTERVIEW"
    OFFER = "OFFER"
    HIRED = "HIRED"
    REJECTED = "REJECTED"
    WITHDRAWN = "WITHDRAWN"


class InterviewStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"
    NO_SHOW = "NO_SHOW"


class OfferStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"
    EXPIRED = "EXPIRED"
    WITHDRAWN = "WITHDRAWN"


class JobPosting(Base):
    """A job opening / requisition."""
    __tablename__ = "job_postings"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    title = Column(String(200), nullable=False)
    department_id = Column(
        String(36), ForeignKey("departments.id", ondelete="SET NULL"), nullable=True
    )
    designation_id = Column(
        String(36), ForeignKey("designations.id", ondelete="SET NULL"), nullable=True
    )

    description = Column(Text, nullable=False)
    requirements = Column(Text, nullable=True)          # Qualifications, skills
    responsibilities = Column(Text, nullable=True)

    job_type = Column(Enum(JobType), default=JobType.FULL_TIME)
    location = Column(String(200), nullable=True)
    salary_min = Column(Float, nullable=True)
    salary_max = Column(Float, nullable=True)
    salary_currency = Column(String(10), default="USD")

    # Posting metadata
    status = Column(Enum(JobStatus), default=JobStatus.DRAFT)
    posted_by = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    posted_date = Column(DateTime(timezone=True), nullable=True)
    closing_date = Column(Date, nullable=True)
    vacancies = Column(Integer, default=1)             # Number of positions
    filled = Column(Integer, default=0)               # How many filled

    is_public = Column(Boolean, default=True)           # Show on career page?
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    department = relationship("Department")
    designation = relationship("Designation")
    poster = relationship("Employee", foreign_keys=[posted_by])
    candidates = relationship("Candidate", back_populates="job_posting", cascade="all, delete-orphan")


class Candidate(Base):
    """A job applicant in the recruitment pipeline."""
    __tablename__ = "candidates"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    job_posting_id = Column(
        String(36), ForeignKey("job_postings.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Personal info
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), nullable=False, index=True)
    phone = Column(String(30), nullable=True)
    linkedin_url = Column(String(500), nullable=True)
    resume_path = Column(String(500), nullable=True)   # Path to uploaded resume

    # Application info
    cover_letter = Column(Text, nullable=True)
    current_position = Column(String(100), nullable=True)
    years_of_experience = Column(Integer, nullable=True)
    expected_salary = Column(Float, nullable=True)

    # Pipeline tracking
    stage = Column(Enum(CandidateStage), default=CandidateStage.APPLIED, nullable=False, index=True)
    source = Column(String(100), nullable=True)        # "LinkedIn", "Referral", "Career Page"
    rating = Column(Integer, nullable=True)             # 1-5 stars from screening

    # If hired, link to employee record
    employee_id = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)

    # Metadata
    applied_at = Column(DateTime(timezone=True), server_default=func.now())
    stage_updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    notes = Column(Text, nullable=True)                # Internal recruiter notes

    # Relationships
    job_posting = relationship("JobPosting", back_populates="candidates")
    interviews = relationship("InterviewSchedule", back_populates="candidate", cascade="all, delete-orphan")
    offers = relationship("OfferLetter", back_populates="candidate", cascade="all, delete-orphan")
    employee = relationship("Employee", foreign_keys=[employee_id])


class InterviewSchedule(Base):
    """Scheduled interview for a candidate."""
    __tablename__ = "interviews"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    candidate_id = Column(
        String(36), ForeignKey("candidates.id", ondelete="CASCADE"), nullable=False, index=True
    )
    job_posting_id = Column(
        String(36), ForeignKey("job_postings.id", ondelete="CASCADE"), nullable=False
    )

    # Interview details
    interview_round = Column(Integer, default=1)      # 1st, 2nd, 3rd round
    interview_type = Column(String(50), nullable=True)  # "Technical", "HR", "Final", "Panel"
    scheduled_at = Column(DateTime(timezone=True), nullable=False)
    duration_minutes = Column(Integer, default=60)
    location = Column(String(200), nullable=True)      # Room or video link
    mode = Column(String(20), default="ONSITE")        # ONSITE, VIDEO, PHONE

    # Interviewers
    interviewer_id = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)

    # Status and feedback
    status = Column(Enum(InterviewStatus), default=InterviewStatus.SCHEDULED, nullable=False)
    feedback = Column(Text, nullable=True)
    rating = Column(Integer, nullable=True)             # 1-5
    recommendation = Column(String(20), nullable=True)  # "HIRE", "NO_HIRE", "STRONG_HIRE"

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    candidate = relationship("Candidate", back_populates="interviews")
    job_posting = relationship("JobPosting")
    interviewer = relationship("Employee", foreign_keys=[interviewer_id])


class OfferLetter(Base):
    """Job offer extended to a candidate."""
    __tablename__ = "offer_letters"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    candidate_id = Column(
        String(36), ForeignKey("candidates.id", ondelete="CASCADE"), nullable=False, index=True
    )
    job_posting_id = Column(
        String(36), ForeignKey("job_postings.id", ondelete="CASCADE"), nullable=False
    )

    # Offer details
    proposed_salary = Column(Float, nullable=False)
    salary_currency = Column(String(10), default="USD")
    job_title = Column(String(200), nullable=False)
    start_date = Column(Date, nullable=False)
    offer_expiry_date = Column(Date, nullable=True)

    # Benefits and terms
    benefits_summary = Column(Text, nullable=True)
    terms_conditions = Column(Text, nullable=True)

    # Status
    status = Column(Enum(OfferStatus), default=OfferStatus.PENDING, nullable=False)
    offered_by = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    offered_at = Column(DateTime(timezone=True), server_default=func.now())
    responded_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    candidate = relationship("Candidate", back_populates="offers")
    job_posting = relationship("JobPosting")
    offerer = relationship("Employee", foreign_keys=[offered_by])
