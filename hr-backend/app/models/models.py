import uuid
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

# Import Base from the core database module (Clean Architecture)
from app.core.database import Base


# Define role types clearly to prevent typos
class RoleEnum(str, enum.Enum):
    ADMIN = "ADMIN"
    MANAGER = "MANAGER"
    STAFF = "STAFF"


# Department table
class Department(Base):
    __tablename__ = "departments"

    # Use UUID instead of auto-increment
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)

    # Automatically record creation time
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # One department has many employees
    employees = relationship("Employee", back_populates="department")


# Import the enhanced models so Base.metadata picks them up
from app.models.employee_enhanced import EmployeeStatus, DocumentType, EmployeeDocument, Designation  # noqa: F401


# Upgraded Employee Model
class Employee(Base):
    __tablename__ = "employees"

    # Use UUID to prevent IDOR attacks
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))

    # Foreign key to the departments table
    department_id = Column(String(36), ForeignKey("departments.id"), nullable=True)

    # Designation (structured job title) — nullable for backward compatibility
    designation_id = Column(String(36), ForeignKey("designations.id", ondelete="SET NULL"), nullable=True)

    # Reporting hierarchy — self-referential FK to build org chart
    manager_id = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)

    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    position = Column(String(50))
    hashed_password = Column(String(255), nullable=False)

    # Use Enum instead of plain String to prevent invalid role values
    role = Column(Enum(RoleEnum), default=RoleEnum.STAFF)
    is_active = Column(Boolean, default=True)

    # Employee lifecycle status
    status = Column(Enum(EmployeeStatus), default=EmployeeStatus.ACTIVE)

    # Additional personal info
    phone = Column(String(30), nullable=True)
    address = Column(Text, nullable=True)
    photo_path = Column(String(500), nullable=True)        # URL or server path to employee photo
    date_of_birth = Column(DateTime, nullable=True)
    hire_date = Column(DateTime, nullable=True)              # Employment start date
    exit_date = Column(DateTime, nullable=True)             # Separation date (if resigned/terminated)

    # Audit logs (creation and last update timestamps)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationship back to the department (ORM Relationship)
    department = relationship("Department", back_populates="employees")

    # Designation relationship
    designation = relationship("Designation", back_populates="employees", foreign_keys=[designation_id])

    # Reporting hierarchy: manager (self-referential) and direct reports
    manager = relationship("Employee", remote_side=[id], backref="direct_reports")
