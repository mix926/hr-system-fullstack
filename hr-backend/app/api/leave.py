from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.leave import LeaveModel, LeaveStatus
from app.schemas.leave import LeaveCreate, LeaveResponse
from app.models.models import Employee
from app.api.auth import get_current_user

router = APIRouter(prefix="/leaves", tags=["Leaves"])


# ---- API Endpoints ----

@router.post("/", response_model=LeaveResponse, status_code=status.HTTP_201_CREATED)
def create_leave_request(
    leave: LeaveCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # ខ្មែរ: current_user ជា dict (JWT payload) ។ email ស្ថិតនៅ key "sub"
    email = current_user.get("sub")
    employee = db.query(Employee).filter(Employee.email == email).first()
    if not employee:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

    db_leave = LeaveModel(
        leave_type=leave.leave_type,
        # ខ្មែរ: បំប្លែង datetime ទៅ string នៅពេល store ដោយ SQLAlchemy ដោះស្រាយ
        start_date=leave.start_date,
        end_date=leave.end_date,
        reason=leave.reason,
        employee_id=employee.id,
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
    # ខ្មែរ: current_user ជា dict (JWT payload) ។ role ស្ថិតនៅ key "role"
    role = current_user.get("role")
    email = current_user.get("sub")

    if role in ["ADMIN", "MANAGER"]:
        return db.query(LeaveModel).all()

    employee = db.query(Employee).filter(Employee.email == email).first()
    if not employee:
        return []

    return db.query(LeaveModel).filter(LeaveModel.employee_id == employee.id).all()
