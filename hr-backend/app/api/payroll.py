from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.payroll import PayrollModel
from app.api.auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/payroll", tags=["Payroll"])


class PayrollCreate(BaseModel):
  # Employee.id is a UUID String, not Integer
  employee_id: str
  month_year: str
  base_salary: float
  bonus: float = 0.0
  deductions: float = 0.0


class PayrollResponse(BaseModel):
  id: int
  employee_id: str
  month_year: str
  base_salary: float
  bonus: float
  deductions: float
  net_salary: float
  status: str

  class Config:
    # Pydantic V2 uses from_attributes instead of orm_mode
    from_attributes = True


@router.post("/", response_model=PayrollResponse)
def create_payroll(
    payroll: PayrollCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
  if current_user.role != "ADMIN":
    raise HTTPException(
        status_code=403, detail="เฉพาะ ADMIN เท่านั้นที่สามารถจัดการ Payroll ได้"
    )

  # Auto-calculate net salary
  net = payroll.base_salary + payroll.bonus - payroll.deductions

  db_payroll = PayrollModel(
      employee_id=payroll.employee_id,
      month_year=payroll.month_year,
      base_salary=payroll.base_salary,
      bonus=payroll.bonus,
      deductions=payroll.deductions,
      net_salary=net,
      status="PAID",
  )
  db.add(db_payroll)
  db.commit()
  db.refresh(db_payroll)
  return db_payroll


@router.get("/", response_model=List[PayrollResponse])
def get_payrolls(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
  if current_user.role in ["ADMIN", "MANAGER"]:
    return db.query(PayrollModel).all()
  return (
      db.query(PayrollModel)
      .filter(PayrollModel.employee_id == current_user.id)
      .all()
  )
