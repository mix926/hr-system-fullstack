from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from app.models.payroll import PayrollStatus


class PayrollBase(BaseModel):
    employee_id: str = Field(..., description="UUID of the employee")
    month_year: str = Field(..., description="Payroll period e.g. '2026-10'")
    base_salary: float = Field(..., ge=0)
    bonus: float = Field(0.0, ge=0)
    deductions: float = Field(0.0, ge=0)


class PayrollCreate(PayrollBase):
    """DTO for creating a new payroll record."""
    pass


class PayrollUpdate(BaseModel):
    """DTO for partially updating a payroll record."""
    base_salary: Optional[float] = Field(None, ge=0)
    bonus: Optional[float] = Field(None, ge=0)
    deductions: Optional[float] = Field(None, ge=0)


class PayrollStatusUpdate(BaseModel):
    """DTO for updating only the status of a payroll record."""
    status: PayrollStatus


class PayrollResponse(BaseModel):
    """DTO for returning payroll data to the frontend."""
    id: int
    employee_id: str
    month_year: str
    base_salary: float
    bonus: float
    deductions: float
    net_salary: float
    status: PayrollStatus
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
