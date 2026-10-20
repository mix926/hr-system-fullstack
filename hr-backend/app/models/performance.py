import enum
from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class ReviewStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    SUBMITTED = "SUBMITTED"
    ACKNOWLEDGED = "ACKNOWLEDGED"


class PerformanceReview(Base):
    __tablename__ = "performance_reviews"

    id = Column(String(36), primary_key=True, index=True,
                default=lambda: __import__('uuid').uuid4().__str__())

    # Employee being reviewed
    employee_id = Column(String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)

    # Employee who submitted the review (reviewer)
    reviewer_id = Column(String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)

    # Review period, e.g. "2025-Q3", "2025 Annual"
    review_period = Column(String(50), nullable=False)

    # Overall rating 1-5
    rating = Column(Integer, nullable=False)

    # Free-text fields
    strengths = Column(Text, nullable=True)
    areas_for_improvement = Column(Text, nullable=True)
    goals = Column(Text, nullable=True)
    comments = Column(Text, nullable=True)

    status = Column(
        Enum(ReviewStatus), default=ReviewStatus.SUBMITTED, nullable=False
    )

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="reviews_received")
    reviewer = relationship("Employee", foreign_keys=[reviewer_id], backref="reviews_given")
