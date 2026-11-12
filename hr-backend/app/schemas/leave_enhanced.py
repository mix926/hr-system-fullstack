"""
Leave Management Enhancement schemas:
- LeaveType CRUD
- LeaveBalance views
- Multi-level approval workflow
- Leave encashment requests
"""
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field
from app.models.leave_enhanced import AccrualFrequency, ApprovalStatus


# ─── LeaveType Schemas ─────────────────────────────────────────

class LeaveTypeBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    accrual_amount: float = Field(0.0, ge=0)
    accrual_frequency: AccrualFrequency = AccrualFrequency.MONTHLY
    max_balance: Optional[float] = None
    carry_forward_enabled: bool = False
    carry_forward_max: Optional[float] = None
    encashable: bool = False
    encashment_rate: float = Field(1.0, ge=0)
    is_paid: bool = True
    requires_approval: bool = True
    approval_levels: int = Field(1, ge=1, le=5)
    is_active: bool = True


class LeaveTypeCreate(LeaveTypeBase):
    pass


class LeaveTypeUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    accrual_amount: Optional[float] = Field(None, ge=0)
    accrual_frequency: Optional[AccrualFrequency] = None
    max_balance: Optional[float] = None
    carry_forward_enabled: Optional[bool] = None
    carry_forward_max: Optional[float] = None
    encashable: Optional[bool] = None
    encashment_rate: Optional[float] = Field(None, ge=0)
    is_paid: Optional[bool] = None
    requires_approval: Optional[bool] = None
    approval_levels: Optional[int] = Field(None, ge=1, le=5)
    is_active: Optional[bool] = None


class LeaveTypeResponse(LeaveTypeBase):
    id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── LeaveBalance Schemas ──────────────────────────────────────

class LeaveBalanceResponse(BaseModel):
    id: str
    employee_id: str
    leave_type_id: str
    leave_type_name: Optional[str] = None  # Joined from LeaveType
    year: int
    balance: float
    carried_forward: float
    accrued: float
    used: float
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class LeaveBalanceCreate(BaseModel):
    """Manually initialize a balance for an employee + leave type + year."""
    employee_id: str
    leave_type_id: str
    year: int
    balance: float = Field(0.0, ge=0)
    carried_forward: float = Field(0.0, ge=0)


# ─── Multi-Level Approval Schemas ─────────────────────────────

class ApprovalAction(BaseModel):
    """Approve or reject a leave request at the current approval level."""
    approved: bool
    comments: Optional[str] = None


class ApprovalStepResponse(BaseModel):
    id: str
    leave_request_id: str
    level: int
    approver_id: Optional[str] = None
    status: str
    comments: Optional[str] = None
    acted_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Leave Encashment Schemas ─────────────────────────────────

class LeaveEncashmentCreate(BaseModel):
    employee_id: str
    leave_type_id: str
    days_encashed: float = Field(..., gt=0)
    daily_salary: float = Field(..., ge=0)


class LeaveEncashmentResponse(BaseModel):
    id: str
    employee_id: str
    leave_type_id: str
    days_encashed: float
    amount: float
    daily_salary: float
    status: str
    processed_by: Optional[str] = None
    processed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class LeaveEncashmentAction(BaseModel):
    """Approve or reject an encashment request."""
    approved: bool


# ─── Enhanced Leave Response (with approval steps) ────────────

class LeaveRequestWithApprovalsResponse(BaseModel):
    """Leave request including all approval steps and balance info."""
    id: str
    employee_id: str
    leave_type: str
    leave_type_id: Optional[str] = None
    start_date: datetime
    end_date: datetime
    reason: Optional[str] = None
    status: str
    current_approval_level: int
    approved_by: Optional[str] = None
    approved_at: Optional[datetime] = None
    days_requested: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True
