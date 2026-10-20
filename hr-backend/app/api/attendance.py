from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.attendance import AttendanceModel
from app.api.auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/attendance", tags=["Attendance"])


class AttendanceResponse(BaseModel):
  id: int
  employee_id: str          # UUID stored as String(36)
  date: str
  check_in_time: Optional[datetime] = None
  check_out_time: Optional[datetime] = None
  status: str

  class Config:
    orm_mode = True


@router.post("/check-in", response_model=AttendanceResponse)
def check_in(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
  """Record a check-in for the current user. Raises 400 if already checked in today."""
  today_str = datetime.now().strftime("%Y-%m-%d")

  # Check whether the employee has already checked in today
  existing = (
      db.query(AttendanceModel)
      .filter(
          AttendanceModel.employee_id == current_user.id,
          AttendanceModel.date == today_str,
      )
      .first()
  )

  if existing:
    raise HTTPException(
        status_code=400, detail="You have already checked in today"
    )

  db_attendance = AttendanceModel(
      employee_id=current_user.id,
      date=today_str,
      check_in_time=datetime.now(),
      status="PRESENT",
  )
  db.add(db_attendance)
  db.commit()
  db.refresh(db_attendance)
  return db_attendance


@router.post("/check-out", response_model=AttendanceResponse)
def check_out(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
  """Record a check-out for the current user. Raises 400 if not checked in or already checked out."""
  today_str = datetime.now().strftime("%Y-%m-%d")

  attendance = (
      db.query(AttendanceModel)
      .filter(
          AttendanceModel.employee_id == current_user.id,
          AttendanceModel.date == today_str,
      )
      .first()
  )

  if not attendance:
    raise HTTPException(
        status_code=400, detail="You have not checked in today"
    )

  if attendance.check_out_time:
    raise HTTPException(
        status_code=400, detail="You have already checked out today"
    )

  attendance.check_out_time = datetime.now()
  db.commit()
  db.refresh(attendance)
  return attendance


@router.get("/", response_model=List[AttendanceResponse])
def get_attendances(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
  """Retrieve attendance records. ADMIN/MANAGER see all; STAFF sees only their own."""
  # Compare role value as string to handle both plain strings and RoleEnum
  role = current_user.role.value if hasattr(current_user.role, "value") else current_user.role
  if role in ["ADMIN", "MANAGER"]:
    return db.query(AttendanceModel).all()
  return (
      db.query(AttendanceModel)
      .filter(AttendanceModel.employee_id == current_user.id)
      .all()
  )
