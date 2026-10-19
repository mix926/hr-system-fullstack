from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.performance import PerformanceReview, ReviewStatus
from app.schemas.performance import (
    PerformanceReviewCreate,
    PerformanceReviewResponse,
    PerformanceReviewUpdate,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/performance", tags=["Performance Reviews"])


@router.post("/", response_model=PerformanceReviewResponse,
             status_code=status.HTTP_201_CREATED)
def create_review(
    review: PerformanceReviewCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a performance review. Only ADMIN or MANAGER can create."""
    role = current_user.role.value if hasattr(current_user.role, "value") else current_user.role
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can create performance reviews",
        )

    if review.rating < 1 or review.rating > 5:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Rating must be between 1 and 5",
        )

    db_review = PerformanceReview(
        employee_id=review.employee_id,
        reviewer_id=current_user.id,
        review_period=review.review_period,
        rating=review.rating,
        strengths=review.strengths,
        areas_for_improvement=review.areas_for_improvement,
        goals=review.goals,
        comments=review.comments,
        status=ReviewStatus.SUBMITTED,
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review


@router.get("/", response_model=List[PerformanceReviewResponse])
def get_reviews(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all reviews (ADMIN/MANAGER) or only reviews about the current user (STAFF)."""
    role = current_user.role.value if hasattr(current_user.role, "value") else current_user.role
    if role in ("ADMIN", "MANAGER"):
        return db.query(PerformanceReview).all()
    return db.query(PerformanceReview).filter(
        PerformanceReview.employee_id == current_user.id
    ).all()


@router.get("/{review_id}", response_model=PerformanceReviewResponse)
def get_review(
    review_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    review = db.query(PerformanceReview).filter(PerformanceReview.id == review_id).first()
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Performance review not found")
    return review


@router.get("/employee/{employee_id}", response_model=List[PerformanceReviewResponse])
def get_reviews_by_employee(
    employee_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all reviews for a specific employee."""
    role = current_user.role.value if hasattr(current_user.role, "value") else current_user.role
    if role not in ("ADMIN", "MANAGER") and employee_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own reviews",
        )
    return db.query(PerformanceReview).filter(
        PerformanceReview.employee_id == employee_id
    ).all()


@router.patch("/{review_id}", response_model=PerformanceReviewResponse)
def update_review(
    review_id: str,
    body: PerformanceReviewUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a review. Only ADMIN or MANAGER can update."""
    role = current_user.role.value if hasattr(current_user.role, "value") else current_user.role
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can update performance reviews",
        )

    review = db.query(PerformanceReview).filter(PerformanceReview.id == review_id).first()
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Performance review not found")

    updates = body.model_dump(exclude_none=True)
    if "status" in updates:
        try:
            review.status = ReviewStatus(updates["status"].upper())
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Invalid status value",
            )
        del updates["status"]

    for key, value in updates.items():
        setattr(review, key, value)

    db.commit()
    db.refresh(review)
    return review


@router.delete("/{review_id}")
def delete_review(
    review_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a review. Only ADMIN can delete."""
    role = current_user.role.value if hasattr(current_user.role, "value") else current_user.role
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can delete performance reviews",
        )

    review = db.query(PerformanceReview).filter(PerformanceReview.id == review_id).first()
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Performance review not found")

    db.delete(review)
    db.commit()
    return {"message": "Performance review deleted successfully"}
