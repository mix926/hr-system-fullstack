"""
Pydantic schemas for Employee Management enhancements:
- Employee documents
- Designations
- Lifecycle status updates
- Reporting hierarchy
"""
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field
from app.models.employee_enhanced import EmployeeStatus, DocumentType


# ─── Document Schemas ──────────────────────────────────────────

class EmployeeDocumentBase(BaseModel):
    document_type: DocumentType
    title: str = Field(..., min_length=1, max_length=200)
    file_path: str
    file_name: str
    expiry_date: Optional[date] = None
    issued_date: Optional[date] = None
    issuing_authority: Optional[str] = None
    notes: Optional[str] = None


class EmployeeDocumentCreate(EmployeeDocumentBase):
    pass


class EmployeeDocumentUpdate(BaseModel):
    document_type: Optional[DocumentType] = None
    title: Optional[str] = None
    expiry_date: Optional[date] = None
    issued_date: Optional[date] = None
    issuing_authority: Optional[str] = None
    notes: Optional[str] = None


class EmployeeDocumentResponse(EmployeeDocumentBase):
    id: str
    employee_id: str
    uploaded_by: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Designation Schemas ───────────────────────────────────────

class DesignationBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    department_id: Optional[str] = None
    grade: Optional[str] = None
    description: Optional[str] = None


class DesignationCreate(DesignationBase):
    pass


class DesignationUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    department_id: Optional[str] = None
    grade: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class DesignationResponse(DesignationBase):
    id: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Employee Lifecycle & Hierarchy Schemas ───────────────────

class EmployeeStatusUpdate(BaseModel):
    """Update the lifecycle status of an employee."""
    status: EmployeeStatus
    exit_date: Optional[datetime] = None  # Required when status is RESIGNED or TERMINATED


class ReportingHierarchyUpdate(BaseModel):
    """Set or change an employee's direct manager."""
    manager_id: Optional[str] = None  # None removes the manager link


class EmployeeDetailResponse(BaseModel):
    """Extended employee response including lifecycle, designation, and hierarchy."""
    id: str
    first_name: str
    last_name: str
    email: str
    position: Optional[str] = None
    department_id: Optional[str] = None
    designation_id: Optional[str] = None
    manager_id: Optional[str] = None
    role: str
    is_active: bool
    status: str
    phone: Optional[str] = None
    address: Optional[str] = None
    photo_path: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    hire_date: Optional[datetime] = None
    exit_date: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class EmployeeProfileUpdate(BaseModel):
    """Self-service profile update — employees can update their own contact info."""
    phone: Optional[str] = None
    address: Optional[str] = None
    photo_path: Optional[str] = None
    date_of_birth: Optional[datetime] = None


class DirectReportResponse(BaseModel):
    """Summary of a direct report for the org chart."""
    id: str
    first_name: str
    last_name: str
    email: str
    position: Optional[str] = None
    status: str

    class Config:
        from_attributes = True
