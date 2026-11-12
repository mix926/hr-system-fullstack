"""
Admin & Security models:

- AuditLog: tracks who changed what, when, on which record
- Company: top-level tenant (multi-company support)
- Branch: sub-unit of a company (multi-branch support)
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class AuditAction(str, enum.Enum):
    """Type of action that was recorded."""
    CREATE = "CREATE"
    UPDATE = "UPDATE"
    DELETE = "DELETE"
    LOGIN = "LOGIN"
    LOGOUT = "LOGOUT"
    APPROVE = "APPROVE"
    REJECT = "REJECT"
    DOWNLOAD = "DOWNLOAD"
    EXPORT = "EXPORT"


class AuditLog(Base):
    """Immutable record of every significant system action.

    Records who (actor_id), what (action on entity_type:entity_id),
    when (created_at), from where (ip_address), and what changed (diff).
    """
    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())

    # Who performed the action
    actor_id = Column(
        String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True, index=True
    )
    actor_email = Column(String(100), nullable=True)  # Denormalized for log permanence

    # What was affected
    action = Column(Enum(AuditAction), nullable=False, index=True)
    entity_type = Column(String(100), nullable=False, index=True)  # e.g. "employee", "leave", "payroll"
    entity_id = Column(String(100), nullable=True)                 # UUID or int of the affected record

    # Description
    description = Column(Text, nullable=True)  # Human-readable summary

    # Change diff — before/after state as JSON
    old_values = Column(JSON, nullable=True)   # State before the change
    new_values = Column(JSON, nullable=True)   # State after the change

    # Request metadata
    ip_address = Column(String(45), nullable=True)  # IPv4 or IPv6
    user_agent = Column(String(500), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    actor = relationship("Employee", foreign_keys=[actor_id])


class Company(Base):
    """Top-level company tenant for multi-company support.

    Every department, employee, etc. would ideally have a company_id FK
    for full multi-tenancy. This model provides the company registry.
    """
    __tablename__ = "companies"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    name = Column(String(200), nullable=False, unique=True)
    legal_name = Column(String(200), nullable=True)
    registration_number = Column(String(100), nullable=True)
    country = Column(String(100), nullable=True)
    timezone = Column(String(50), default="UTC")
    currency = Column(String(10), default="USD")
    logo_path = Column(String(500), nullable=True)

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    branches = relationship("Branch", back_populates="company", cascade="all, delete-orphan")


class Branch(Base):
    """A branch or office of a company.

    Employees can be assigned to a branch for location-based HR management.
    """
    __tablename__ = "branches"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    company_id = Column(
        String(36), ForeignKey("companies.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name = Column(String(200), nullable=False)
    code = Column(String(20), nullable=True)  # e.g. "HQ", "NYC", "DXB"
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    country = Column(String(100), nullable=True)
    phone = Column(String(30), nullable=True)
    email = Column(String(100), nullable=True)

    # Branch manager
    manager_id = Column(
        String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True
    )

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    company = relationship("Company", back_populates="branches")
    manager = relationship("Employee", foreign_keys=[manager_id])
