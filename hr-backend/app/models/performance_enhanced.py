"""
Performance Management Enhancement models:

- Goal (OKR/KPI): objectives with key results, progress tracking
- Review360: 360-degree review from peers, subordinates, managers
- PerformanceImprovementPlan: structured PIP with milestones and outcomes
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text, Integer, Float, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
from app.models.performance import ReviewStatus


class GoalType(str, enum.Enum):
    OKR = "OKR"     # Objective & Key Results
    KPI = "KPI"     # Key Performance Indicator
    PERSONAL = "PERSONAL"  # Personal development goal


class GoalStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    EXPIRED = "EXPIRED"
    CANCELLED = "CANCELLED"


class ReviewType(str, enum.Enum):
    """360-degree review relationship types."""
    SELF = "SELF"
    MANAGER = "MANAGER"
    PEER = "PEER"
    SUBORDINATE = "SUBORDINATE"
    EXTERNAL = "EXTERNAL"   # Client or cross-functional


class PIPStatus(str, enum.Enum):
    """Performance Improvement Plan status."""
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"       # Successfully improved
    EXTENDED = "EXTENDED"        # Given more time
    FAILED = "FAILED"            # Did not meet objectives
    CANCELLED = "CANCELLED"      # Left company or other reason


class Goal(Base):
    """An OKR, KPI, or personal development goal.

    An objective can have key results (sub-goals) via parent_id.
    """
    __tablename__ = "goals"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Goal hierarchy — parent_id for key results under an objective
    parent_goal_id = Column(
        String(36), ForeignKey("goals.id", ondelete="CASCADE"), nullable=True
    )

    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)

    goal_type = Column(Enum(GoalType), default=GoalType.OKR, nullable=False)
    status = Column(Enum(GoalStatus), default=GoalStatus.DRAFT, nullable=False)

    # Measurement
    target_value = Column(Float, nullable=True)
    current_value = Column(Float, default=0.0)
    unit = Column(String(50), nullable=True)            # "%", "count", "$", etc.
    weight = Column(Float, default=1.0)                # For weighted scoring

    # Period
    period = Column(String(50), nullable=False)        # "2026-Q4", "2026 Annual"
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)

    # Who set the goal
    set_by = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="goals")
    setter = relationship("Employee", foreign_keys=[set_by])
    parent = relationship("Goal", remote_side=[id], backref="key_results")


class Review360(Base):
    """A 360-degree review from different perspectives (self, peer, subordinate, manager).

    Multiple Review360 records can be linked to a single PerformanceReview
    by sharing the same employee_id + review_period.
    """
    __tablename__ = "reviews_360"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())

    # The employee being reviewed
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # The person giving the review
    reviewer_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False
    )

    review_type = Column(Enum(ReviewType), nullable=False)
    review_period = Column(String(50), nullable=False)

    # Ratings (1-5 scale for each competency)
    rating = Column(Integer, nullable=False)          # Overall rating

    # Competency-specific ratings as JSON: {"communication": 4, "leadership": 3, "technical": 5}
    competency_ratings = Column(Text, nullable=True)   # JSON string

    # Free-text feedback
    strengths = Column(Text, nullable=True)
    areas_for_improvement = Column(Text, nullable=True)
    comments = Column(Text, nullable=True)

    # Anonymity — reviewer name can be hidden from the reviewed employee
    is_anonymous = Column(Boolean, default=False)
    status = Column(Enum(ReviewStatus), default=ReviewStatus.SUBMITTED, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="reviews_360_received")
    reviewer = relationship("Employee", foreign_keys=[reviewer_id], backref="reviews_360_given")


class PerformanceImprovementPlan(Base):
    """A structured PIP with objectives, milestones, and outcome tracking.

    Used when an employee is underperforming and needs a formal improvement plan.
    """
    __tablename__ = "performance_improvement_plans"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())

    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_by = Column(
        String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True
    )

    # PIP details
    title = Column(String(200), nullable=False)
    reason = Column(Text, nullable=False)             # Why the PIP was initiated
    objectives = Column(Text, nullable=False)           # What the employee needs to achieve
    support_provided = Column(Text, nullable=True)      # Training, mentoring, resources

    # Duration
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)            # Review/end date
    review_frequency = Column(String(50), default="WEEKLY")  # "WEEKLY", "BIWEEKLY", "MONTHLY"

    # Status
    status = Column(Enum(PIPStatus), default=PIPStatus.ACTIVE, nullable=False)

    # Outcome (filled when completed)
    outcome_summary = Column(Text, nullable=True)
    outcome_rating = Column(Integer, nullable=True)    # 1-5 final rating

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="pips")
    creator = relationship("Employee", foreign_keys=[created_by])
    milestones = relationship("PIPMilestone", back_populates="pip", cascade="all, delete-orphan")


class PIPMilestone(Base):
    """A check-in milestone within a PIP."""
    __tablename__ = "pip_milestones"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    pip_id = Column(
        String(36), ForeignKey("performance_improvement_plans.id", ondelete="CASCADE"), nullable=False, index=True
    )

    milestone_date = Column(Date, nullable=False)
    description = Column(Text, nullable=False)        # What will be assessed
    met = Column(Boolean, nullable=True)             # Was it achieved?
    notes = Column(Text, nullable=True)
    reviewed_by = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    pip = relationship("PerformanceImprovementPlan", back_populates="milestones")
    reviewer = relationship("Employee", foreign_keys=[reviewed_by])
