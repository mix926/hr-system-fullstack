"""
Employee Document, Lifecycle, and Organizational Structure models.

This module adds:
- Employee lifecycle status (onboarding → active → on_leave → resigned → terminated)
- Designation (job title distinct from generic 'position')
- Reporting hierarchy via manager_id
- Document management with expiry alerts (contracts, IDs, certificates)
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class EmployeeStatus(str, enum.Enum):
    """Employee lifecycle stages."""
    ONBOARDING = "ONBOARDING"   # Newly hired, completing setup
    ACTIVE = "ACTIVE"           # Fully employed and working
    ON_LEAVE = "ON_LEAVE"       # On extended leave (sabbatical, maternity, etc.)
    RESIGNED = "RESIGNED"       # Voluntarily left the company
    TERMINATED = "TERMINATED"    # Involuntarily separated
    PROBATION = "PROBATION"     # Under probationary period


class DocumentType(str, enum.Enum):
    """Types of employee documents for categorization and expiry tracking."""
    CONTRACT = "CONTRACT"
    NATIONAL_ID = "NATIONAL_ID"
    PASSPORT = "PASSPORT"
    PASSPORT_VISA = "VISA"
    DRIVING_LICENSE = "DRIVING_LICENSE"
    EDUCATION_CERT = "EDUCATION_CERT"
    PROFESSIONAL_CERT = "PROFESSIONAL_CERT"
    MEDICAL = "MEDICAL"
    OTHER = "OTHER"


class EmployeeDocument(Base):
    """Documents attached to an employee profile (contracts, IDs, certificates).

    Supports expiry alerts — frontend can query documents nearing expiry.
    """
    __tablename__ = "employee_documents"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )

    document_type = Column(Enum(DocumentType), nullable=False)
    title = Column(String(200), nullable=False)          # Human-readable label, e.g. "Employment Contract 2026"
    file_path = Column(String(500), nullable=False)        # Server-side path or URL to stored file
    file_name = Column(String(255), nullable=False)        # Original uploaded filename

    # Expiry tracking — null means document does not expire
    expiry_date = Column(Date, nullable=True)

    # Metadata
    issued_date = Column(Date, nullable=True)              # When the document was issued
    issuing_authority = Column(String(200), nullable=True)  # E.g. "Ministry of Labor", "DMV"
    notes = Column(Text, nullable=True)

    # Audit
    uploaded_by = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="documents")
    uploader = relationship("Employee", foreign_keys=[uploaded_by])


class Designation(Base):
    """Job designation / title — separate from the free-text 'position' field.

    Designations are reusable across employees and belong to a department.
    This enables structured org charts and reporting hierarchies.
    """
    __tablename__ = "designations"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    name = Column(String(100), nullable=False, unique=True)  # e.g. "Senior Software Engineer"
    department_id = Column(String(36), ForeignKey("departments.id", ondelete="SET NULL"), nullable=True)
    grade = Column(String(20), nullable=True)               # e.g. "L5", "M2" for salary grade mapping
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    department = relationship("Department")
    employees = relationship("Employee", back_populates="designation", foreign_keys="Employee.designation_id")
