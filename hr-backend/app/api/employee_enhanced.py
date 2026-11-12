"""
Employee Management Enhancement API endpoints:

- Document CRUD with expiry tracking
- Designation CRUD
- Employee lifecycle status management
- Reporting hierarchy (org chart)
- Extended employee profile (personal info, photo)
- Self-service profile update
- Documents expiring soon (for alerts)
"""
from datetime import date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
import os
import uuid

from app.core.database import get_db
from app.models.models import Employee, RoleEnum
from app.models.employee_enhanced import (
    EmployeeDocument,
    Designation,
    EmployeeStatus,
    DocumentType,
)
from app.schemas.employee_enhanced import (
    EmployeeDocumentCreate,
    EmployeeDocumentUpdate,
    EmployeeDocumentResponse,
    DesignationCreate,
    DesignationUpdate,
    DesignationResponse,
    EmployeeStatusUpdate,
    ReportingHierarchyUpdate,
    EmployeeDetailResponse,
    EmployeeProfileUpdate,
    DirectReportResponse,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/employees", tags=["Employee Management"])

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


# ─── Document Management ───────────────────────────────────────

# Directory for storing uploaded documents
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads", "documents")
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/{employee_id}/documents/upload", response_model=EmployeeDocumentResponse,
             status_code=status.HTTP_201_CREATED)
async def upload_document(
    employee_id: str,
    document_type: str = Form(...),
    title: str = Form(...),
    file: UploadFile = File(...),
    expiry_date: Optional[str] = Form(None),
    issued_date: Optional[str] = Form(None),
    issuing_authority: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload a document for an employee. ADMIN/MANAGER can upload for anyone;
    STAFF can upload for themselves only."""
    if _role(current_user) == "STAFF" and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only upload documents for yourself")

    # Validate employee exists
    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    # Validate document type
    try:
        doc_type = DocumentType(document_type)
    except ValueError:
        raise HTTPException(status_code=422, detail=f"Invalid document type. Valid: {[dt.value for dt in DocumentType]}")

    # Save file
    file_ext = os.path.splitext(file.filename)[1]
    saved_name = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(UPLOAD_DIR, saved_name)
    content = await file.read()
    with open(file_path, "wb") as f:
        f.write(content)

    # Parse dates
    from datetime import datetime as dt
    parsed_expiry = dt.strptime(expiry_date, "%Y-%m-%d").date() if expiry_date else None
    parsed_issued = dt.strptime(issued_date, "%Y-%m-%d").date() if issued_date else None

    doc = EmployeeDocument(
        employee_id=employee_id,
        document_type=doc_type,
        title=title,
        file_path=file_path,
        file_name=file.filename,
        expiry_date=parsed_expiry,
        issued_date=parsed_issued,
        issuing_authority=issuing_authority,
        notes=notes,
        uploaded_by=current_user.id,
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return doc


@router.get("/{employee_id}/documents", response_model=List[EmployeeDocumentResponse])
def get_employee_documents(
    employee_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all documents for an employee. ADMIN/MANAGER see all; STAFF sees own only."""
    if _role(current_user) == "STAFF" and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view your own documents")
    return db.query(EmployeeDocument).filter(EmployeeDocument.employee_id == employee_id).all()


@router.patch("/documents/{document_id}", response_model=EmployeeDocumentResponse)
def update_document(
    document_id: str,
    updates: EmployeeDocumentUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update document metadata (title, expiry, notes). ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    doc = db.query(EmployeeDocument).filter(EmployeeDocument.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    for key, value in updates.model_dump(exclude_none=True).items():
        setattr(doc, key, value)
    db.commit()
    db.refresh(doc)
    return doc


@router.delete("/documents/{document_id}")
def delete_document(
    document_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a document and its file. ADMIN only."""
    _require_admin(current_user)
    doc = db.query(EmployeeDocument).filter(EmployeeDocument.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    # Try to remove the physical file
    if doc.file_path and os.path.exists(doc.file_path):
        os.remove(doc.file_path)
    db.delete(doc)
    db.commit()
    return {"message": "Document deleted successfully"}


@router.get("/documents/expiring-soon", response_model=List[EmployeeDocumentResponse])
def get_expiring_documents(
    days: int = 30,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get documents expiring within N days. ADMIN/MANAGER see all; STAFF sees own only."""
    threshold = date.today() + timedelta(days=days)
    query = db.query(EmployeeDocument).filter(
        EmployeeDocument.expiry_date.isnot(None),
        EmployeeDocument.expiry_date <= threshold,
    )
    if _role(current_user) == "STAFF":
        query = query.filter(EmployeeDocument.employee_id == current_user.id)
    return query.order_by(EmployeeDocument.expiry_date.asc()).all()


# ─── Designation Management ────────────────────────────────────

@router.get("/designations", response_model=List[DesignationResponse])
def get_designations(
    department_id: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all designations. Optionally filter by department."""
    query = db.query(Designation)
    if department_id:
        query = query.filter(Designation.department_id == department_id)
    return query.all()


@router.post("/designations", response_model=DesignationResponse, status_code=status.HTTP_201_CREATED)
def create_designation(
    body: DesignationCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new designation. ADMIN only."""
    _require_admin(current_user)
    existing = db.query(Designation).filter(Designation.name == body.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Designation already exists")
    designation = Designation(**body.model_dump())
    db.add(designation)
    db.commit()
    db.refresh(designation)
    return designation


@router.patch("/designations/{designation_id}", response_model=DesignationResponse)
def update_designation(
    designation_id: str,
    body: DesignationUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a designation. ADMIN only."""
    _require_admin(current_user)
    designation = db.query(Designation).filter(Designation.id == designation_id).first()
    if not designation:
        raise HTTPException(status_code=404, detail="Designation not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(designation, key, value)
    db.commit()
    db.refresh(designation)
    return designation


@router.delete("/designations/{designation_id}")
def delete_designation(
    designation_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a designation. ADMIN only."""
    _require_admin(current_user)
    designation = db.query(Designation).filter(Designation.id == designation_id).first()
    if not designation:
        raise HTTPException(status_code=404, detail="Designation not found")
    db.delete(designation)
    db.commit()
    return {"message": "Designation deleted successfully"}


# ─── Employee Lifecycle Management ─────────────────────────────

@router.patch("/{employee_id}/status", response_model=EmployeeDetailResponse)
def update_employee_status(
    employee_id: str,
    body: EmployeeStatusUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update employee lifecycle status. ADMIN only.
    
    When transitioning to RESIGNED or TERMINATED, exit_date should be provided.
    """
    _require_admin(current_user)
    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    emp.status = body.status

    # Set exit date when leaving the company
    if body.status in (EmployeeStatus.RESIGNED, EmployeeStatus.TERMINATED):
        emp.exit_date = body.exit_date or date.today()
        emp.is_active = False
    elif body.status == EmployeeStatus.ACTIVE:
        emp.is_active = True
        emp.exit_date = None

    db.commit()
    db.refresh(emp)
    return emp


# ─── Reporting Hierarchy ───────────────────────────────────────

@router.patch("/{employee_id}/manager", response_model=EmployeeDetailResponse)
def set_manager(
    employee_id: str,
    body: ReportingHierarchyUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Set or change an employee's reporting manager. ADMIN only.
    
    Pass manager_id=null to remove the reporting link.
    Prevents circular reporting (employee cannot be their own manager ancestor).
    """
    _require_admin(current_user)
    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    if body.manager_id is not None:
        # Prevent self-reference
        if body.manager_id == employee_id:
            raise HTTPException(status_code=422, detail="Employee cannot report to themselves")

        # Prevent circular hierarchy — walk up the chain
        manager = db.query(Employee).filter(Employee.id == body.manager_id).first()
        if not manager:
            raise HTTPException(status_code=404, detail="Manager not found")

        visited = {employee_id}
        current = manager
        while current:
            if current.id in visited:
                raise HTTPException(status_code=422, detail="Circular reporting hierarchy detected")
            visited.add(current.id)
            current = current.manager

    emp.manager_id = body.manager_id
    db.commit()
    db.refresh(emp)
    return emp


@router.get("/{employee_id}/direct-reports", response_model=List[DirectReportResponse])
def get_direct_reports(
    employee_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all direct reports of an employee (for org chart / team overview)."""
    # Managers can view their own team; admins can view anyone's
    if _role(current_user) not in ("ADMIN", "MANAGER") and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")

    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    return emp.direct_reports


@router.get("/{employee_id}/org-chart")
def get_org_chart(
    employee_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the full reporting chain from an employee up to the top.
    
    Returns a list of {id, name, position, manager_id} from the employee upward.
    """
    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    chain = []
    current = emp
    visited = set()
    while current:
        if current.id in visited:
            break  # Safety against cycles
        visited.add(current.id)
        chain.append({
            "id": current.id,
            "first_name": current.first_name,
            "last_name": current.last_name,
            "position": current.position,
            "manager_id": current.manager_id,
        })
        current = current.manager

    return {"chain": chain}


# ─── Extended Employee Profile ─────────────────────────────────

@router.get("/{employee_id}/profile", response_model=EmployeeDetailResponse)
def get_employee_profile(
    employee_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the full extended profile of an employee.
    
    ADMIN/MANAGER can view anyone; STAFF can only view their own profile.
    """
    if _role(current_user) == "STAFF" and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view your own profile")

    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    return emp


@router.patch("/{employee_id}/profile", response_model=EmployeeDetailResponse)
def update_employee_profile(
    employee_id: str,
    body: EmployeeProfileUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Self-service profile update. STAFF can update their own contact info.
    ADMIN/MANAGER can update anyone's profile."""
    if _role(current_user) == "STAFF" and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only update your own profile")

    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    for key, value in body.model_dump(exclude_none=True).items():
        setattr(emp, key, value)
    db.commit()
    db.refresh(emp)
    return emp
