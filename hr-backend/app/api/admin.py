"""
Admin & Security API:

- Audit logs: list with filters (actor, entity, action, date range), export CSV
- Company CRUD (multi-company/tenant management)
- Branch CRUD (multi-branch management)
- System health / stats endpoint
"""
import csv
import io
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.audit import AuditLog, AuditAction, Company, Branch
from app.schemas.audit import (
    AuditLogResponse,
    CompanyCreate,
    CompanyUpdate,
    CompanyResponse,
    BranchCreate,
    BranchUpdate,
    BranchResponse,
)
from app.api.auth import get_current_user
from app.services.audit_service import log_action

router = APIRouter(prefix="/admin", tags=["Admin & Security"])

# ── Helpers ────────────────────────────────────────────────────

def _role(user) -> str:
    return user.role.value if hasattr(user.role, "value") else user.role


def _require_admin(user):
    if _role(user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can perform this action",
        )


def _require_admin_or_manager(user):
    role = _role(user)
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can perform this action",
        )


# ─── Audit Log Endpoints ───────────────────────────────────────

@router.get("/audit-logs", response_model=List[AuditLogResponse])
def get_audit_logs(
    actor_id: Optional[str] = None,
    entity_type: Optional[str] = None,
    action: Optional[str] = None,
    date_from: Optional[str] = Query(None, description="YYYY-MM-DD"),
    date_to: Optional[str] = Query(None, description="YYYY-MM-DD"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List audit logs with filters. ADMIN only.
    
    Supports filtering by actor, entity type, action type, and date range.
    """
    _require_admin(current_user)

    query = db.query(AuditLog)

    if actor_id:
        query = query.filter(AuditLog.actor_id == actor_id)
    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)
    if action:
        try:
            query = query.filter(AuditLog.action == AuditAction(action))
        except ValueError:
            raise HTTPException(status_code=422, detail=f"Invalid action. Valid: {[a.value for a in AuditAction]}")
    if date_from:
        df = datetime.strptime(date_from, "%Y-%m-%d")
        query = query.filter(AuditLog.created_at >= df)
    if date_to:
        dt = datetime.strptime(date_to, "%Y-%m-%d")
        query = query.filter(AuditLog.created_at <= dt)

    return (
        query
        .order_by(AuditLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )


@router.get("/audit-logs/export")
def export_audit_logs(
    entity_type: Optional[str] = None,
    action: Optional[str] = None,
    date_from: Optional[str] = Query(None, description="YYYY-MM-DD"),
    date_to: Optional[str] = Query(None, description="YYYY-MM-DD"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Export audit logs as CSV. ADMIN only."""
    _require_admin(current_user)

    logs = get_audit_logs(
        actor_id=None,
        entity_type=entity_type,
        action=action,
        date_from=date_from,
        date_to=date_to,
        limit=10000,
        offset=0,
        current_user=current_user,
        db=db,
    )

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Timestamp", "Actor Email", "Action", "Entity Type", "Entity ID", "Description", "IP Address"])
    for log in logs:
        writer.writerow([
            log.created_at.strftime("%Y-%m-%d %H:%M:%S") if log.created_at else "",
            log.actor_email or "",
            log.action.value if hasattr(log.action, "value") else str(log.action),
            log.entity_type,
            log.entity_id or "",
            log.description or "",
            log.ip_address or "",
        ])
    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode("utf-8")),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=audit_log.csv"}
    )


@router.get("/audit-logs/{entity_type}/{entity_id}", response_model=List[AuditLogResponse])
def get_entity_audit_trail(
    entity_type: str,
    entity_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the complete audit trail for a specific record. ADMIN only."""
    _require_admin(current_user)
    return (
        db.query(AuditLog)
        .filter(
            AuditLog.entity_type == entity_type,
            AuditLog.entity_id == entity_id,
        )
        .order_by(AuditLog.created_at.asc())
        .all()
    )


# ─── Company Management ────────────────────────────────────────

@router.get("/companies", response_model=List[CompanyResponse])
def get_companies(
    active_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all companies. ADMIN only."""
    _require_admin(current_user)
    query = db.query(Company)
    if active_only:
        query = query.filter(Company.is_active == True)
    return query.order_by(Company.name.asc()).all()


@router.post("/companies", response_model=CompanyResponse, status_code=status.HTTP_201_CREATED)
def create_company(
    body: CompanyCreate,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new company. ADMIN only."""
    _require_admin(current_user)
    existing = db.query(Company).filter(Company.name == body.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Company already exists")
    company = Company(**body.model_dump())
    db.add(company)
    db.commit()
    db.refresh(company)

    log_action(
        db=db, actor=current_user,
        action=AuditAction.CREATE,
        entity_type="company",
        entity_id=company.id,
        description=f"Created company: {company.name}",
        new_values={"name": company.name, "country": company.country},
        request=request,
    )
    return company


@router.patch("/companies/{company_id}", response_model=CompanyResponse)
def update_company(
    company_id: str,
    body: CompanyUpdate,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a company. ADMIN only."""
    _require_admin(current_user)
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    old_values = {"name": company.name, "country": company.country}
    updates = body.model_dump(exclude_none=True)
    for key, value in updates.items():
        setattr(company, key, value)
    db.commit()
    db.refresh(company)

    log_action(
        db=db, actor=current_user,
        action=AuditAction.UPDATE,
        entity_type="company",
        entity_id=company_id,
        description=f"Updated company: {company.name}",
        old_values=old_values,
        new_values=updates,
        request=request,
    )
    return company


@router.delete("/companies/{company_id}")
def delete_company(
    company_id: str,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Soft-delete a company (deactivate). ADMIN only."""
    _require_admin(current_user)
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    company.is_active = False
    db.commit()

    log_action(
        db=db, actor=current_user,
        action=AuditAction.DELETE,
        entity_type="company",
        entity_id=company_id,
        description=f"Deactivated company: {company.name}",
        request=request,
    )
    return {"message": "Company deactivated"}


# ─── Branch Management ─────────────────────────────────────────

@router.get("/companies/{company_id}/branches", response_model=List[BranchResponse])
def get_branches(
    company_id: str,
    active_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List branches for a company. ADMIN only."""
    _require_admin(current_user)
    query = db.query(Branch).filter(Branch.company_id == company_id)
    if active_only:
        query = query.filter(Branch.is_active == True)
    return query.order_by(Branch.name.asc()).all()


@router.post("/branches", response_model=BranchResponse, status_code=status.HTTP_201_CREATED)
def create_branch(
    body: BranchCreate,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new branch. ADMIN only."""
    _require_admin(current_user)
    company = db.query(Company).filter(Company.id == body.company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    branch = Branch(**body.model_dump())
    db.add(branch)
    db.commit()
    db.refresh(branch)

    log_action(
        db=db, actor=current_user,
        action=AuditAction.CREATE,
        entity_type="branch",
        entity_id=branch.id,
        description=f"Created branch: {branch.name} for {company.name}",
        new_values={"name": branch.name, "city": branch.city, "country": branch.country},
        request=request,
    )
    return branch


@router.patch("/branches/{branch_id}", response_model=BranchResponse)
def update_branch(
    branch_id: str,
    body: BranchUpdate,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a branch. ADMIN only."""
    _require_admin(current_user)
    branch = db.query(Branch).filter(Branch.id == branch_id).first()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    old_values = {"name": branch.name, "city": branch.city}
    updates = body.model_dump(exclude_none=True)
    for key, value in updates.items():
        setattr(branch, key, value)
    db.commit()
    db.refresh(branch)

    log_action(
        db=db, actor=current_user,
        action=AuditAction.UPDATE,
        entity_type="branch",
        entity_id=branch_id,
        description=f"Updated branch: {branch.name}",
        old_values=old_values,
        new_values=updates,
        request=request,
    )
    return branch


@router.delete("/branches/{branch_id}")
def delete_branch(
    branch_id: str,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Soft-delete a branch. ADMIN only."""
    _require_admin(current_user)
    branch = db.query(Branch).filter(Branch.id == branch_id).first()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    branch.is_active = False
    db.commit()

    log_action(
        db=db, actor=current_user,
        action=AuditAction.DELETE,
        entity_type="branch",
        entity_id=branch_id,
        description=f"Deactivated branch: {branch.name}",
        request=request,
    )
    return {"message": "Branch deactivated"}


# ─── Admin Utility Endpoints ───────────────────────────────────

@router.get("/stats")
def get_system_stats(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get system-wide stats dashboard for admins."""
    _require_admin_or_manager(current_user)
    from app.models.models import Employee, Department
    from app.models.leave import LeaveModel, LeaveStatus
    from app.models.payroll import PayrollModel, PayrollStatus
    from app.models.recruitment import JobPosting, JobStatus, Candidate
    from app.models.notification import Notification

    return {
        "employees": {
            "total": db.query(Employee).count(),
            "active": db.query(Employee).filter(Employee.is_active == True).count(),
        },
        "departments": db.query(Department).count(),
        "leave_requests": {
            "total": db.query(LeaveModel).count(),
            "pending": db.query(LeaveModel).filter(LeaveModel.status == LeaveStatus.PENDING).count(),
        },
        "payroll": {
            "total": db.query(PayrollModel).count(),
            "pending": db.query(PayrollModel).filter(PayrollModel.status == PayrollStatus.PENDING).count(),
            "paid": db.query(PayrollModel).filter(PayrollModel.status == PayrollStatus.PAID).count(),
        },
        "recruitment": {
            "open_jobs": db.query(JobPosting).filter(JobPosting.status == JobStatus.OPEN).count(),
            "total_candidates": db.query(Candidate).count(),
        },
        "audit_logs_today": db.query(AuditLog).filter(
            AuditLog.created_at >= datetime.utcnow().replace(hour=0, minute=0, second=0)
        ).count(),
    }


@router.post("/audit-logs")
def create_audit_log_manual(
    entity_type: str,
    entity_id: str,
    action: str,
    description: str,
    request: Request,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Manually create an audit log entry. ADMIN only. Used for system events."""
    _require_admin(current_user)
    try:
        audit_action = AuditAction(action)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid action. Valid: {[a.value for a in AuditAction]}")

    log = log_action(
        db=db, actor=current_user,
        action=audit_action,
        entity_type=entity_type,
        entity_id=entity_id,
        description=description,
        request=request,
    )
    return {"message": "Audit log created", "id": log.id}
