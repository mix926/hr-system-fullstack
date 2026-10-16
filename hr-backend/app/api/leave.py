from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.leave import LeaveModel, LeaveStatus
from app.schemas.leave import LeaveCreate, LeaveResponse
from app.models.models import Employee
from app.api.auth import get_current_user

router = APIRouter(prefix="/leaves", tags=["Leaves"])


# ---- API Endpoints ----

@router.get("/stats")
def get_leave_stats(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """ខ្មែរ: ទាញយករាប់ចំនួនសំណើច្បាប់តាម Status (ADMIN/MANAGER ឃើញទាំងអស់ / STAFF ឃើញតែរបស់ខ្លួន)"""
    role  = current_user.role
    if role in ["ADMIN", "MANAGER"]:
        query = db.query(LeaveModel)
    else:
        query = db.query(LeaveModel).filter(
            LeaveModel.employee_id == current_user.id
        )

    total    = query.count()
    pending  = query.filter(LeaveModel.status == LeaveStatus.PENDING).count()
    approved = query.filter(LeaveModel.status == LeaveStatus.APPROVED).count()
    rejected = query.filter(LeaveModel.status == LeaveStatus.REJECTED).count()

    return {
        "total":    total,
        "pending":  pending,
        "approved": approved,
        "rejected": rejected,
    }

class LeaveStatusUpdate(BaseModel):
    status: str  # "APPROVED" or "REJECTED"


# ---- API Endpoints ----

@router.post("/", response_model=LeaveResponse, status_code=status.HTTP_201_CREATED)
def create_leave_request(
    leave: LeaveCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # ខ្មែរ: current_user ជា Employee object ។ ប្រើ attribute access បានផ្ទាល់
    db_leave = LeaveModel(
        leave_type=leave.leave_type,
        start_date=leave.start_date,
        end_date=leave.end_date,
        reason=leave.reason,
        employee_id=current_user.id,
        status=LeaveStatus.PENDING
    )
    db.add(db_leave)
    db.commit()
    db.refresh(db_leave)
    return db_leave


@router.get("/", response_model=List[LeaveResponse])
def get_leave_requests(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # ខ្មែរ: ADMIN/MANAGER ឃើញសំណើទាំងអស់ / STAFF ឃើញតែរបស់ខ្លួន
    if current_user.role in ["ADMIN", "MANAGER"]:
        return db.query(LeaveModel).all()

    return db.query(LeaveModel).filter(LeaveModel.employee_id == current_user.id).all()


@router.patch("/{leave_id}/status", response_model=LeaveResponse)
def update_leave_status(
    leave_id: str,
    body: LeaveStatusUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    ខ្មែរ: Endpoint សម្រាប់ ADMIN/MANAGER ដើម្បីអនុម័ត (APPROVED) ឬបដិសេធ (REJECTED)
    សំណើសុំច្បាប់។ STAFF មិនមានសិទ្ធិប្រើ Endpoint នេះ។
    """
    role = current_user.role
    if role not in ["ADMIN", "MANAGER"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can update leave status"
        )

    # ខ្មែរ: ត្រួតពិនិត្យ status ថាត្រូវជា APPROVED ឬ REJECTED ប៉ុណ្ណោះ
    allowed = {s.value for s in LeaveStatus} - {"PENDING"}
    if body.status.upper() not in allowed:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Status must be one of: {', '.join(allowed)}"
        )

    db_leave = db.query(LeaveModel).filter(LeaveModel.id == leave_id).first()
    if not db_leave:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave request not found")

    db_leave.status = LeaveStatus(body.status.upper())
    db.commit()
    db.refresh(db_leave)
    return db_leave
