# Location: app/api/attendance.py
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.attendance import AttendanceModel
from app.api.auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/attendance", tags=["Attendance"])


class AttendanceResponse(BaseModel):
  id: int
  employee_id: int
  date: str
  check_in_time: str | None = None
  check_out_time: str | None = None
  status: str

  class Config:
    orm_mode = True


@router.post("/check-in", response_model=AttendanceResponse)
def check_in(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
  today_str = datetime.now().strftime("%Y-%m-%d")

  # ពិនិត្យមើលថាតើធ្លាប់ Check-in ថ្ងៃនេះរួចរាល់ហើយឬยัง
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
        status_code=400, detail="คุณได้ Check-in ในวันนี้เรียบร้อยแล้ว"
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
        status_code=400, detail="คุณยังไม่ได้ Check-in ในวันนี้"
    )

  if attendance.check_out_time:
    raise HTTPException(
        status_code=400, detail="คุณได้ Check-out ไปแล้วในวันนี้"
    )

  attendance.check_out_time = datetime.now()
  db.commit()
  db.refresh(attendance)
  return attendance


@router.get("/", response_model=List[AttendanceResponse])
def get_attendances(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
  if current_user.role in ["ADMIN", "MANAGER"]:
    return db.query(AttendanceModel).all()
  return (
      db.query(AttendanceModel)
      .filter(AttendanceModel.employee_id == current_user.id)
      .all()
  )