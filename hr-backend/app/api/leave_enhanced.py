"""
Leave Management Enhancement API:

- LeaveType CRUD (configure leave types with accrual rules)
- LeaveBalance: view, initialize, accrual run
- Multi-level approval workflow (approve/reject at each level)
- Carry-forward: year-end processing
- Leave encashment: request, approve, reject
"""
from datetime import datetime, date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import extract

from app.core.database import get_db
from app.models.models import Employee
from app.models.leave import LeaveModel, LeaveStatus
from app.models.leave_enhanced import (
    LeaveType,
    LeaveBalance,
    LeaveApprovalStep,
    LeaveEncashment,
    ApprovalStatus,
    AccrualFrequency,
)
from app.schemas.leave_enhanced import (
    LeaveTypeCreate,
    LeaveTypeUpdate,
    LeaveTypeResponse,
    LeaveBalanceResponse,
    LeaveBalanceCreate,
    ApprovalAction,
    ApprovalStepResponse,
    LeaveEncashmentCreate,
    LeaveEncashmentResponse,
    LeaveEncashmentAction,
    LeaveRequestWithApprovalsResponse,
)
from app.schemas.leave import LeaveCreate, LeaveResponse
from app.api.auth import get_current_user

router = APIRouter(prefix="/leave", tags=["Leave Management"])

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


def _require_admin(user):
    if _role(user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can perform this action",
        )


def _calc_days(start_date: datetime, end_date: datetime) -> int:
    """Calculate leave days inclusive of start and end."""
    delta = end_date.date() - start_date.date()
    return delta.days + 1


def _get_or_create_balance(
    db: Session, employee_id: str, leave_type_id: str, year: int
) -> LeaveBalance:
    """Get existing balance or create a new one."""
    balance = db.query(LeaveBalance).filter(
        LeaveBalance.employee_id == employee_id,
        LeaveBalance.leave_type_id == leave_type_id,
        LeaveBalance.year == year,
    ).first()
    if not balance:
        balance = LeaveBalance(
            employee_id=employee_id,
            leave_type_id=leave_type_id,
            year=year,
            balance=0.0,
            carried_forward=0.0,
            accrued=0.0,
            used=0.0,
        )
        db.add(balance)
        db.commit()
        db.refresh(balance)
    return balance


# ─── LeaveType CRUD ────────────────────────────────────────────

@router.get("/types", response_model=List[LeaveTypeResponse])
def get_leave_types(
    active_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all leave types. Optionally filter to active only."""
    query = db.query(LeaveType)
    if active_only:
        query = query.filter(LeaveType.is_active == True)
    return query.all()


@router.post("/types", response_model=LeaveTypeResponse, status_code=status.HTTP_201_CREATED)
def create_leave_type(
    body: LeaveTypeCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new leave type with accrual rules. ADMIN only."""
    _require_admin(current_user)
    existing = db.query(LeaveType).filter(LeaveType.name == body.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Leave type already exists")
    leave_type = LeaveType(**body.model_dump())
    db.add(leave_type)
    db.commit()
    db.refresh(leave_type)
    return leave_type


@router.patch("/types/{type_id}", response_model=LeaveTypeResponse)
def update_leave_type(
    type_id: str,
    body: LeaveTypeUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a leave type. ADMIN only."""
    _require_admin(current_user)
    lt = db.query(LeaveType).filter(LeaveType.id == type_id).first()
    if not lt:
        raise HTTPException(status_code=404, detail="Leave type not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(lt, key, value)
    db.commit()
    db.refresh(lt)
    return lt


@router.delete("/types/{type_id}")
def delete_leave_type(
    type_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a leave type. ADMIN only."""
    _require_admin(current_user)
    lt = db.query(LeaveType).filter(LeaveType.id == type_id).first()
    if not lt:
        raise HTTPException(status_code=404, detail="Leave type not found")
    lt.is_active = False
    db.commit()
    return {"message": "Leave type deactivated"}


# ─── Leave Balance ─────────────────────────────────────────────

@router.get("/balances/{employee_id}", response_model=List[LeaveBalanceResponse])
def get_leave_balances(
    employee_id: str,
    year: Optional[int] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get leave balances for an employee. ADMIN/MANAGER see all; STAFF sees own only."""
    if _role(current_user) == "STAFF" and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view your own balances")
    query = db.query(LeaveBalance).filter(LeaveBalance.employee_id == employee_id)
    if year:
        query = query.filter(LeaveBalance.year == year)
    else:
        query = query.filter(LeaveBalance.year == date.today().year)
    balances = query.all()
    # Enrich with leave type name
    result = []
    for b in balances:
        lt = db.query(LeaveType).filter(LeaveType.id == b.leave_type_id).first()
        resp = LeaveBalanceResponse.model_validate(b)
        resp.leave_type_name = lt.name if lt else None
        result.append(resp)
    return result


@router.post("/balances", response_model=LeaveBalanceResponse, status_code=status.HTTP_201_CREATED)
def initialize_balance(
    body: LeaveBalanceCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Initialize a leave balance for an employee. ADMIN only."""
    _require_admin(current_user)
    existing = db.query(LeaveBalance).filter(
        LeaveBalance.employee_id == body.employee_id,
        LeaveBalance.leave_type_id == body.leave_type_id,
        LeaveBalance.year == body.year,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Balance already exists for this year")
    balance = LeaveBalance(**body.model_dump())
    db.add(balance)
    db.commit()
    db.refresh(balance)
    return balance


@router.post("/balances/accrue")
def run_accrual(
    year: Optional[int] = None,
    month: Optional[int] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Run accrual for all employees for a given period. ADMIN only.
    
    Adds accrual_amount to each employee's balance for each active leave type.
    Respects max_balance cap.
    """
    _require_admin(current_user)
    now = date.today()
    target_year = year or now.year
    target_month = month or now.month

    leave_types = db.query(LeaveType).filter(LeaveType.is_active == True).all()
    employees = db.query(Employee).filter(Employee.is_active == True).all()

    results = []
    for lt in leave_types:
        for emp in employees:
            balance = _get_or_create_balance(db, emp.id, lt.id, target_year)

            # Check frequency matches current period
            should_accrue = False
            if lt.accrual_frequency == AccrualFrequency.MONTHLY:
                should_accrue = True
            elif lt.accrual_frequency == AccrualFrequency.QUARTERLY and target_month % 3 == 0:
                should_accrue = True
            elif lt.accrual_frequency == AccrualFrequency.SEMI_ANNUAL and target_month in (6, 12):
                should_accrue = True
            elif lt.accrual_frequency == AccrualFrequency.ANNUAL and target_month == 12:
                should_accrue = True
            elif lt.accrual_frequency == AccrualFrequency.LUMP_SUM and target_month == 1:
                should_accrue = True

            if should_accrue and lt.accrual_amount > 0:
                new_balance = balance.balance + lt.accrual_amount
                # Apply max balance cap
                if lt.max_balance is not None:
                    new_balance = min(new_balance, lt.max_balance)
                balance.balance = new_balance
                balance.accrued += lt.accrual_amount
                results.append({
                    "employee_id": emp.id,
                    "leave_type": lt.name,
                    "accrued": lt.accrual_amount,
                    "new_balance": new_balance,
                })

    db.commit()
    return {"message": "Accrual complete", "processed": len(results), "details": results}


# ─── Multi-Level Approval Workflow ─────────────────────────────

@router.post("/requests", response_model=LeaveRequestWithApprovalsResponse,
             status_code=status.HTTP_201_CREATED)
def create_leave_request_enhanced(
    body: LeaveCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new leave request with multi-level approval workflow.
    
    If leave_type_id is provided, validates balance and creates approval steps.
    Falls back to legacy free-text leave_type if no leave_type_id.
    """
    days = _calc_days(body.start_date, body.end_date)

    # If leave_type_id provided, check balance
    leave_type = None
    if hasattr(body, "leave_type_id") and body.leave_type_id:
        leave_type = db.query(LeaveType).filter(LeaveType.id == body.leave_type_id).first()
        if not leave_type:
            raise HTTPException(status_code=404, detail="Leave type not found")

        balance = _get_or_create_balance(db, current_user.id, leave_type.id, body.start_date.year)
        if leave_type.is_paid and balance.balance < days:
            raise HTTPException(
                status_code=422,
                detail=f"Insufficient leave balance. Available: {balance.balance}, Requested: {days}"
            )

    leave = LeaveModel(
        leave_type=body.leave_type,
        leave_type_id=leave_type.id if leave_type else None,
        start_date=body.start_date,
        end_date=body.end_date,
        reason=body.reason,
        employee_id=current_user.id,
        status=LeaveStatus.PENDING,
        current_approval_level=1,
        days_requested=days,
    )
    db.add(leave)
    db.commit()
    db.refresh(leave)

    # Create approval steps if leave type has multi-level approval
    if leave_type and leave_type.requires_approval and leave_type.approval_levels > 1:
        for level in range(1, leave_type.approval_levels + 1):
            step = LeaveApprovalStep(
                leave_request_id=leave.id,
                level=level,
                status=ApprovalStatus.PENDING,
            )
            db.add(step)
        db.commit()

    return leave


@router.patch("/requests/{leave_id}/approve", response_model=LeaveRequestWithApprovalsResponse)
def approve_or_reject_leave(
    leave_id: str,
    body: ApprovalAction,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Approve or reject a leave request at the current approval level.
    
    MANAGER can approve level 1 (direct reports).
    ADMIN can approve any level.
    
    When all levels are approved, leave status becomes APPROVED and balance is deducted.
    If rejected at any level, status becomes REJECTED.
    """
    _require_admin_or_manager(current_user)

    leave = db.query(LeaveModel).filter(LeaveModel.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="Leave request not found")
    if leave.status != LeaveStatus.PENDING:
        raise HTTPException(status_code=400, detail=f"Leave is already {leave.status.value}")

    # Find current pending approval step
    current_step = db.query(LeaveApprovalStep).filter(
        LeaveApprovalStep.leave_request_id == leave.id,
        LeaveApprovalStep.status == ApprovalStatus.PENDING,
    ).order_by(LeaveApprovalStep.level.asc()).first()

    # Reject path
    if not body.approved:
        if current_step:
            current_step.status = ApprovalStatus.REJECTED
            current_step.approver_id = current_user.id
            current_step.comments = body.comments
            current_step.acted_at = datetime.utcnow()
        leave.status = LeaveStatus.REJECTED
        leave.approved_by = current_user.id
        leave.approved_at = datetime.utcnow()
        db.commit()
        db.refresh(leave)
        return leave

    # Approve path
    if current_step:
        # Manager can only approve if they manage the employee (level 1)
        if _role(current_user) == "MANAGER" and current_step.level == 1:
            if leave.employee.manager_id != current_user.id:
                raise HTTPException(status_code=403, detail="You can only approve leave for your direct reports")

        current_step.status = ApprovalStatus.APPROVED
        current_step.approver_id = current_user.id
        current_step.comments = body.comments
        current_step.acted_at = datetime.utcnow()

    # Check if there are more pending steps
    remaining_steps = db.query(LeaveApprovalStep).filter(
        LeaveApprovalStep.leave_request_id == leave.id,
        LeaveApprovalStep.status == ApprovalStatus.PENDING,
    ).count()

    if remaining_steps == 0:
        # All levels approved — finalize
        leave.status = LeaveStatus.APPROVED
        leave.approved_by = current_user.id
        leave.approved_at = datetime.utcnow()

        # Deduct from balance if linked to a leave type
        if leave.leave_type_id and leave.days_requested:
            balance = _get_or_create_balance(
                db, leave.employee_id, leave.leave_type_id, leave.start_date.year
            )
            balance.balance -= leave.days_requested
            balance.used += leave.days_requested
    else:
        leave.current_approval_level += 1

    db.commit()
    db.refresh(leave)
    return leave


@router.get("/requests/{leave_id}/approvals", response_model=List[ApprovalStepResponse])
def get_approval_steps(
    leave_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all approval steps for a leave request."""
    leave = db.query(LeaveModel).filter(LeaveModel.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=404, detail="Leave request not found")
    if _role(current_user) == "STAFF" and leave.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    return db.query(LeaveApprovalStep).filter(
        LeaveApprovalStep.leave_request_id == leave_id
    ).order_by(LeaveApprovalStep.level.asc()).all()


# ─── Carry-Forward ─────────────────────────────────────────────

@router.post("/carry-forward")
def run_carry_forward(
    from_year: int,
    to_year: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Run year-end carry-forward. ADMIN only.
    
    For each employee + leave type with carry_forward_enabled:
    - Moves remaining balance (up to carry_forward_max) to next year as carried_forward
    - Resets current year balance to 0
    """
    _require_admin(current_user)

    leave_types = db.query(LeaveType).filter(
        LeaveType.is_active == True,
        LeaveType.carry_forward_enabled == True,
    ).all()

    results = []
    for lt in leave_types:
        balances = db.query(LeaveBalance).filter(
            LeaveBalance.leave_type_id == lt.id,
            LeaveBalance.year == from_year,
        ).all()

        for bal in balances:
            carry_amount = min(bal.balance, lt.carry_forward_max or bal.balance)
            if carry_amount > 0:
                # Create next year's balance with carry-forward
                next_bal = _get_or_create_balance(db, bal.employee_id, lt.id, to_year)
                next_bal.carried_forward += carry_amount
                next_bal.balance += carry_amount
                # Zero out current year
                bal.balance -= carry_amount
                results.append({
                    "employee_id": bal.employee_id,
                    "leave_type": lt.name,
                    "carried_forward": carry_amount,
                })

    db.commit()
    return {"message": "Carry-forward complete", "processed": len(results), "details": results}


# ─── Leave Encashment ──────────────────────────────────────────

@router.post("/encashments", response_model=LeaveEncashmentResponse,
             status_code=status.HTTP_201_CREATED)
def request_encashment(
    body: LeaveEncashmentCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Request to encash unused leave. STAFF can request for self; ADMIN for anyone."""
    if _role(current_user) == "STAFF" and body.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only request encashment for yourself")

    lt = db.query(LeaveType).filter(LeaveType.id == body.leave_type_id).first()
    if not lt:
        raise HTTPException(status_code=404, detail="Leave type not found")
    if not lt.encashable:
        raise HTTPException(status_code=422, detail="This leave type is not encashable")

    balance = _get_or_create_balance(db, body.employee_id, lt.id, date.today().year)
    if balance.balance < body.days_encashed:
        raise HTTPException(
            status_code=422,
            detail=f"Insufficient balance. Available: {balance.balance}, Requested: {body.days_encashed}"
        )

    amount = body.days_encashed * lt.encashment_rate * body.daily_salary

    encashment = LeaveEncashment(
        employee_id=body.employee_id,
        leave_type_id=body.leave_type_id,
        days_encashed=body.days_encashed,
        amount=amount,
        daily_salary=body.daily_salary,
        status=ApprovalStatus.PENDING,
    )
    db.add(encashment)
    db.commit()
    db.refresh(encashment)
    return encashment


@router.get("/encashments", response_model=List[LeaveEncashmentResponse])
def get_encashments(
    employee_id: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List encashment requests. ADMIN sees all; STAFF sees own only."""
    query = db.query(LeaveEncashment)
    if _role(current_user) == "STAFF":
        query = query.filter(LeaveEncashment.employee_id == current_user.id)
    elif employee_id:
        query = query.filter(LeaveEncashment.employee_id == employee_id)
    return query.order_by(LeaveEncashment.created_at.desc()).all()


@router.patch("/encashments/{encashment_id}", response_model=LeaveEncashmentResponse)
def process_encashment(
    encashment_id: str,
    body: LeaveEncashmentAction,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Approve or reject an encashment request. ADMIN only.
    
    When approved, deducts encashed days from balance.
    """
    _require_admin(current_user)
    enc = db.query(LeaveEncashment).filter(LeaveEncashment.id == encashment_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="Encashment request not found")
    if enc.status != ApprovalStatus.PENDING:
        raise HTTPException(status_code=400, detail=f"Encashment already {enc.status.value}")

    if body.approved:
        enc.status = ApprovalStatus.APPROVED
        # Deduct from balance
        balance = _get_or_create_balance(db, enc.employee_id, enc.leave_type_id, date.today().year)
        balance.balance -= enc.days_encashed
        balance.used += enc.days_encashed
    else:
        enc.status = ApprovalStatus.REJECTED

    enc.processed_by = current_user.id
    enc.processed_at = datetime.utcnow()
    db.commit()
    db.refresh(enc)
    return enc
