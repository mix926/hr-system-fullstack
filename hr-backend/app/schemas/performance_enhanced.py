"""
Performance Management Enhancement schemas:
- Goal (OKR/KPI) CRUD
- 360-degree review management
- PIP (Performance Improvement Plan) with milestones
"""
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field
from app.models.performance_enhanced import (
    GoalType,
    GoalStatus,
    ReviewType,
    PIPStatus,
)
from app.models.performance import ReviewStatus


# ─── Goal / OKR / KPI Schemas ──────────────────────────────────

class GoalBase(BaseModel):
    employee_id: str
    parent_goal_id: Optional[str] = None
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    goal_type: GoalType = GoalType.OKR
    target_value: Optional[float] = None
    current_value: float = Field(0.0, ge=0)
    unit: Optional[str] = None
    weight: float = Field(1.0, ge=0)
    period: str = Field(..., min_length=1, max_length=50)
    start_date: Optional[date] = None
    end_date: Optional[date] = None


class GoalCreate(GoalBase):
    pass


class GoalUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    goal_type: Optional[GoalType] = None
    status: Optional[GoalStatus] = None
    target_value: Optional[float] = None
    current_value: Optional[float] = Field(None, ge=0)
    unit: Optional[str] = None
    weight: Optional[float] = Field(None, ge=0)
    end_date: Optional[date] = None


class GoalProgressUpdate(BaseModel):
    """Update progress on a goal."""
    current_value: float = Field(..., ge=0)
    status: Optional[GoalStatus] = None


class GoalResponse(GoalBase):
    id: str
    status: GoalStatus
    set_by: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── 360° Review Schemas ───────────────────────────────────────

class Review360Base(BaseModel):
    employee_id: str
    review_type: ReviewType
    review_period: str = Field(..., min_length=1, max_length=50)
    rating: int = Field(..., ge=1, le=5)
    competency_ratings: Optional[str] = None  # JSON string
    strengths: Optional[str] = None
    areas_for_improvement: Optional[str] = None
    comments: Optional[str] = None
    is_anonymous: bool = False


class Review360Create(Review360Base):
    pass


class Review360Update(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5)
    competency_ratings: Optional[str] = None
    strengths: Optional[str] = None
    areas_for_improvement: Optional[str] = None
    comments: Optional[str] = None
    status: Optional[ReviewStatus] = None


class Review360Response(Review360Base):
    id: str
    reviewer_id: str
    status: ReviewStatus
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── PIP Schemas ───────────────────────────────────────────────

class PIPMilestoneBase(BaseModel):
    milestone_date: date
    description: str
    met: Optional[bool] = None
    notes: Optional[str] = None


class PIPMilestoneCreate(PIPMilestoneBase):
    pass


class PIPMilestoneUpdate(BaseModel):
    met: Optional[bool] = None
    notes: Optional[str] = None
    reviewed_by: Optional[str] = None


class PIPMilestoneResponse(PIPMilestoneBase):
    id: str
    pip_id: str
    reviewed_by: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class PIPBase(BaseModel):
    employee_id: str
    title: str = Field(..., min_length=1, max_length=200)
    reason: str
    objectives: str
    support_provided: Optional[str] = None
    start_date: date
    end_date: date
    review_frequency: str = "WEEKLY"


class PIPCreate(PIPBase):
    pass


class PIPUpdate(BaseModel):
    title: Optional[str] = None
    reason: Optional[str] = None
    objectives: Optional[str] = None
    support_provided: Optional[str] = None
    end_date: Optional[date] = None
    review_frequency: Optional[str] = None
    status: Optional[PIPStatus] = None
    outcome_summary: Optional[str] = None
    outcome_rating: Optional[int] = Field(None, ge=1, le=5)


class PIPResponse(PIPBase):
    id: str
    created_by: Optional[str] = None
    status: PIPStatus
    outcome_summary: Optional[str] = None
    outcome_rating: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    milestones: List[PIPMilestoneResponse] = []

    class Config:
        from_attributes = True
