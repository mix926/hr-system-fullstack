from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.payroll import PayrollModel, PayrollStatus
from app.schemas.payroll import (
    PayrollCreate,
    PayrollUpdate,
    PayrollStatusUpdate,
    PayrollResponse,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/api/v1/payroll", tags=["Payroll"])


def _role(current_user) -> str:
    return current_user.role.value if hasattr(current_user.role, "value") else current_user.role


# ── Create a payroll record ────────────────────────────────────
@router.post("/", response_model=PayrollResponse, status_code=status.HTTP_201_CREATED)
def create_payroll(
    payroll: PayrollCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new payroll record. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can manage payroll",
        )

    net = payroll.base_salary + payroll.bonus - payroll.deductions
    db_payroll = PayrollModel(
        employee_id=payroll.employee_id,
        month_year=payroll.month_year,
        base_salary=payroll.base_salary,
        bonus=payroll.bonus,
        deductions=payroll.deductions,
        net_salary=net,
        status=PayrollStatus.PENDING,
    )
    db.add(db_payroll)
    db.commit()
    db.refresh(db_payroll)
    return db_payroll


# ── List payrolls ──────────────────────────────────────────────
@router.get("/", response_model=List[PayrollResponse])
def get_payrolls(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
    """Get all payrolls (ADMIN/MANAGER) or only own payrolls (STAFF)."""
    if _role(current_user) in ("ADMIN", "MANAGER"):
        return db.query(PayrollModel).order_by(PayrollModel.created_at.desc()).all()
    return (
        db.query(PayrollModel)
        .filter(PayrollModel.employee_id == current_user.id)
        .order_by(PayrollModel.created_at.desc())
        .all()
    )


# ── Get a single payroll by id ─────────────────────────────────
@router.get("/{payroll_id}", response_model=PayrollResponse)
def get_payroll(
    payroll_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve a single payroll record by ID."""
    payroll = db.query(PayrollModel).filter(PayrollModel.id == payroll_id).first()
    if not payroll:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Payroll record not found"
        )

    # Staff can only see their own payroll
    if _role(current_user) == "STAFF" and payroll.employee_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own payroll records",
        )
    return payroll


# ── Update payroll status ──────────────────────────────────────
@router.patch("/{payroll_id}/status", response_model=PayrollResponse)
def update_payroll_status(
    payroll_id: int,
    body: PayrollStatusUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the status of a payroll record. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can update payroll status",
        )

    payroll = db.query(PayrollModel).filter(PayrollModel.id == payroll_id).first()
    if not payroll:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Payroll record not found"
        )

    payroll.status = body.status
    db.commit()
    db.refresh(payroll)
    return payroll


# ── Partially update a payroll record ──────────────────────────
@router.patch("/{payroll_id}", response_model=PayrollResponse)
def update_payroll(
    payroll_id: int,
    body: PayrollUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update salary fields of a payroll record. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can update payroll records",
        )

    payroll = db.query(PayrollModel).filter(PayrollModel.id == payroll_id).first()
    if not payroll:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Payroll record not found"
        )

    updates = body.model_dump(exclude_none=True)
    for key, value in updates.items():
        setattr(payroll, key, value)

    # Recalculate net salary if any financial field changed
    payroll.net_salary = payroll.base_salary + payroll.bonus - payroll.deductions

    db.commit()
    db.refresh(payroll)
    return payroll


# ── Delete a payroll record ────────────────────────────────────
@router.delete("/{payroll_id}")
def delete_payroll(
    payroll_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a payroll record. ADMIN only."""
    if _role(current_user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can delete payroll records",
        )

    payroll = db.query(PayrollModel).filter(PayrollModel.id == payroll_id).first()
    if not payroll:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Payroll record not found"
        )

    db.delete(payroll)
    db.commit()
    return {"message": "Payroll record deleted successfully"}


# ── Payroll statistics ─────────────────────────────────────────
@router.get("/stats/summary")
def get_payroll_stats(
    current_user=Depends(get_current_user), db: Session = Depends(get_db)
):
    """Get payroll summary statistics. ADMIN/MANAGER only."""
    if _role(current_user) not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can view payroll stats",
        )

    total = db.query(PayrollModel).count()
    pending = db.query(PayrollModel).filter(PayrollModel.status == PayrollStatus.PENDING).count()
    paid = db.query(PayrollModel).filter(PayrollModel.status == PayrollStatus.PAID).count()
    cancelled = db.query(PayrollModel).filter(PayrollModel.status == PayrollStatus.CANCELLED).count()

    # Total net salary paid
    total_paid_amount = (
        db.query(PayrollModel)
        .filter(PayrollModel.status == PayrollStatus.PAID)
        .with_entities(PayrollModel.net_salary)
        .all()
    )
    total_paid_value = sum(row[0] for row in total_paid_amount)

    return {
        "total": total,
        "pending": pending,
        "paid": paid,
        "cancelled": cancelled,
        "total_paid_amount": total_paid_value,
    }
