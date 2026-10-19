from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class PerformanceReviewBase(BaseModel):
    employee_id: str
    review_period: str = Field(..., min_length=1, max_length=50)
    rating: int = Field(..., ge=1, le=5)
    strengths: Optional[str] = None
    areas_for_improvement: Optional[str] = None
    goals: Optional[str] = None
    comments: Optional[str] = None


class PerformanceReviewCreate(PerformanceReviewBase):
    pass


class PerformanceReviewUpdate(BaseModel):
    review_period: Optional[str] = Field(None, min_length=1, max_length=50)
    rating: Optional[int] = Field(None, ge=1, le=5)
    strengths: Optional[str] = None
    areas_for_improvement: Optional[str] = None
    goals: Optional[str] = None
    comments: Optional[str] = None
    status: Optional[str] = None


class PerformanceReviewResponse(PerformanceReviewBase):
    id: str
    reviewer_id: str
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
