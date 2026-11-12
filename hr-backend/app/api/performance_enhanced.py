"""
Performance Management Enhancement API:

- Goal (OKR/KPI) CRUD + progress tracking
- 360° review management (self, peer, subordinate, manager)
- PIP (Performance Improvement Plan) with milestones
"""
from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import Employee
from app.models.performance_enhanced import (
    Goal,
    Review360,
    PerformanceImprovementPlan,
    PIPMilestone,
    GoalType,
    GoalStatus,
    ReviewType,
    PIPStatus,
)
from app.models.performance import ReviewStatus
from app.schemas.performance_enhanced import (
    GoalCreate,
    GoalUpdate,
    GoalProgressUpdate,
    GoalResponse,
    Review360Create,
    Review360Update,
    Review360Response,
    PIPCreate,
    PIPUpdate,
    PIPResponse,
    PIPMilestoneCreate,
    PIPMilestoneUpdate,
    PIPMilestoneResponse,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/performance", tags=["Performance Management"])

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


# ─── Goal / OKR / KPI Endpoints ────────────────────────────────

@router.get("/goals", response_model=List[GoalResponse])
def get_goals(
    employee_id: Optional[str] = None,
    period: Optional[str] = None,
    goal_type: Optional[str] = None,
    status_filter: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List goals. ADMIN/MANAGER see all; STAFF sees own only."""
    query = db.query(Goal)
    if _role(current_user) == "STAFF":
        query = query.filter(Goal.employee_id == current_user.id)
    elif employee_id:
        query = query.filter(Goal.employee_id == employee_id)
    if period:
        query = query.filter(Goal.period == period)
    if goal_type:
        try:
            query = query.filter(Goal.goal_type == GoalType(goal_type))
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid goal type")
    if status_filter:
        try:
            query = query.filter(Goal.status == GoalStatus(status_filter))
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid status")
    return query.order_by(Goal.created_at.desc()).all()


@router.post("/goals", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(
    body: GoalCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a goal/OKR/KPI. ADMIN/MANAGER can create for anyone; STAFF for self only."""
    if _role(current_user) == "STAFF" and body.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only create goals for yourself")
    goal = Goal(
        **body.model_dump(),
        set_by=current_user.id,
        status=GoalStatus.DRAFT,
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal


@router.patch("/goals/{goal_id}", response_model=GoalResponse)
def update_goal(
    goal_id: str,
    body: GoalUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a goal. ADMIN/MANAGER can update any; STAFF own only."""
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if _role(current_user) == "STAFF" and goal.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only update your own goals")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(goal, key, value)
    db.commit()
    db.refresh(goal)
    return goal


@router.patch("/goals/{goal_id}/progress", response_model=GoalResponse)
def update_goal_progress(
    goal_id: str,
    body: GoalProgressUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update progress on a goal. ADMIN/MANAGER or the goal owner."""
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if _role(current_user) == "STAFF" and goal.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    goal.current_value = body.current_value
    if body.status:
        goal.status = body.status
    elif goal.target_value and goal.current_value >= goal.target_value:
        goal.status = GoalStatus.COMPLETED
    db.commit()
    db.refresh(goal)
    return goal


@router.delete("/goals/{goal_id}")
def delete_goal(
    goal_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a goal. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    goal = db.query(Goal).filter(Goal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    db.delete(goal)
    db.commit()
    return {"message": "Goal deleted"}


# ─── 360° Review Endpoints ─────────────────────────────────────

@router.get("/reviews360", response_model=List[Review360Response])
def get_360_reviews(
    employee_id: Optional[str] = None,
    review_period: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List 360° reviews. ADMIN/MANAGER see all; STAFF sees reviews about self only."""
    query = db.query(Review360)
    if _role(current_user) == "STAFF":
        query = query.filter(Review360.employee_id == current_user.id)
    elif employee_id:
        query = query.filter(Review360.employee_id == employee_id)
    if review_period:
        query = query.filter(Review360.review_period == review_period)
    return query.order_by(Review360.created_at.desc()).all()


@router.post("/reviews360", response_model=Review360Response, status_code=status.HTTP_201_CREATED)
def create_360_review(
    body: Review360Create,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a 360° review. ADMIN/MANAGER can create for anyone; STAFF for self-review only."""
    if _role(current_user) == "STAFF" and body.employee_id != current_user.id:
        # Staff can only submit self-reviews
        if body.review_type != ReviewType.SELF:
            raise HTTPException(status_code=403, detail="Staff can only submit self-reviews")
    review = Review360(
        **body.model_dump(),
        reviewer_id=current_user.id,
        status=ReviewStatus.SUBMITTED,
    )
    db.add(review)
    db.commit()
    db.refresh(review)
    return review


@router.patch("/reviews360/{review_id}", response_model=Review360Response)
def update_360_review(
    review_id: str,
    body: Review360Update,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a 360° review. Only the original reviewer or ADMIN can update."""
    review = db.query(Review360).filter(Review360.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    if _role(current_user) != "ADMIN" and review.reviewer_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only update your own reviews")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(review, key, value)
    db.commit()
    db.refresh(review)
    return review


@router.delete("/reviews360/{review_id}")
def delete_360_review(
    review_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a 360° review. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(status_code=403, detail="Only ADMIN can delete reviews")
    review = db.query(Review360).filter(Review360.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    db.delete(review)
    db.commit()
    return {"message": "Review deleted"}


# ─── PIP Endpoints ─────────────────────────────────────────────

@router.get("/pips", response_model=List[PIPResponse])
def get_pips(
    employee_id: Optional[str] = None,
    status_filter: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List PIPs. ADMIN/MANAGER see all; STAFF sees own only."""
    query = db.query(PerformanceImprovementPlan)
    if _role(current_user) == "STAFF":
        query = query.filter(PerformanceImprovementPlan.employee_id == current_user.id)
    elif employee_id:
        query = query.filter(PerformanceImprovementPlan.employee_id == employee_id)
    if status_filter:
        try:
            query = query.filter(PerformanceImprovementPlan.status == PIPStatus(status_filter))
        except ValueError:
            raise HTTPException(status_code=422, detail="Invalid status")
    return query.order_by(PerformanceImprovementPlan.created_at.desc()).all()


@router.post("/pips", response_model=PIPResponse, status_code=status.HTTP_201_CREATED)
def create_pip(
    body: PIPCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a PIP. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    pip = PerformanceImprovementPlan(
        **body.model_dump(),
        created_by=current_user.id,
        status=PIPStatus.ACTIVE,
    )
    db.add(pip)
    db.commit()
    db.refresh(pip)
    return pip


@router.get("/pips/{pip_id}", response_model=PIPResponse)
def get_pip(
    pip_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a PIP by ID."""
    pip = db.query(PerformanceImprovementPlan).filter(PerformanceImprovementPlan.id == pip_id).first()
    if not pip:
        raise HTTPException(status_code=404, detail="PIP not found")
    if _role(current_user) == "STAFF" and pip.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    return pip


@router.patch("/pips/{pip_id}", response_model=PIPResponse)
def update_pip(
    pip_id: str,
    body: PIPUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a PIP. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    pip = db.query(PerformanceImprovementPlan).filter(PerformanceImprovementPlan.id == pip_id).first()
    if not pip:
        raise HTTPException(status_code=404, detail="PIP not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(pip, key, value)
    db.commit()
    db.refresh(pip)
    return pip


@router.delete("/pips/{pip_id}")
def delete_pip(
    pip_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a PIP. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(status_code=403, detail="Only ADMIN can delete PIPs")
    pip = db.query(PerformanceImprovementPlan).filter(PerformanceImprovementPlan.id == pip_id).first()
    if not pip:
        raise HTTPException(status_code=404, detail="PIP not found")
    db.delete(pip)
    db.commit()
    return {"message": "PIP deleted"}


# ─── PIP Milestones ────────────────────────────────────────────

@router.post("/pips/{pip_id}/milestones", response_model=PIPMilestoneResponse, status_code=status.HTTP_201_CREATED)
def add_pip_milestone(
    pip_id: str,
    body: PIPMilestoneCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Add a milestone to a PIP. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    pip = db.query(PerformanceImprovementPlan).filter(PerformanceImprovementPlan.id == pip_id).first()
    if not pip:
        raise HTTPException(status_code=404, detail="PIP not found")
    milestone = PIPMilestone(pip_id=pip_id, **body.model_dump())
    db.add(milestone)
    db.commit()
    db.refresh(milestone)
    return milestone


@router.patch("/pips/{pip_id}/milestones/{milestone_id}", response_model=PIPMilestoneResponse)
def update_pip_milestone(
    pip_id: str,
    milestone_id: str,
    body: PIPMilestoneUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a PIP milestone (mark met/not met, add notes). ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    milestone = db.query(PIPMilestone).filter(
        PIPMilestone.id == milestone_id,
        PIPMilestone.pip_id == pip_id,
    ).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(milestone, key, value)
    if body.reviewed_by is None:
        milestone.reviewed_by = current_user.id
    db.commit()
    db.refresh(milestone)
    return milestone


@router.delete("/pips/{pip_id}/milestones/{milestone_id}")
def delete_pip_milestone(
    pip_id: str,
    milestone_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a PIP milestone. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(status_code=403, detail="Only ADMIN can delete milestones")
    milestone = db.query(PIPMilestone).filter(
        PIPMilestone.id == milestone_id,
        PIPMilestone.pip_id == pip_id,
    ).first()
    if not milestone:
        raise HTTPException(status_code=404, detail="Milestone not found")
    db.delete(milestone)
    db.commit()
    return {"message": "Milestone deleted"}
