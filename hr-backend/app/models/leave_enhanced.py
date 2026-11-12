"""
Leave Management Enhancement models:

- LeaveType: configurable leave types with accrual rules (annual, sick, maternity, etc.)
- LeaveBalance: per-employee balance tracking with carry-forward
- LeaveApprovalStep: multi-level approval workflow tracking
- LeaveEncashment: encashment requests for unused leave
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text, Integer, Float, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class AccrualFrequency(str, enum.Enum):
    """How often leave balance accrues."""
    MONTHLY = "MONTHLY"
    QUARTERLY = "QUARTERLY"
    SEMI_ANNUAL = "SEMI_ANNUAL"
    ANNUAL = "ANNUAL"
    LUMP_SUM = "LUMP_SUM"  # Full allocation at start of year


class LeaveType(Base):
    """Configurable leave types with accrual rules.

    Examples:
    - Annual Leave: 2.5 days/month, carry-forward max 10, encashable
    - Sick Leave: 1.5 days/month, no carry-forward, not encashable
    - Maternity Leave: 90 days lump sum, no carry-forward
    - Unpaid Leave: 0 accrual, no balance tracking
    """
    __tablename__ = "leave_types"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    name = Column(String(100), nullable=False, unique=True)  # "Annual Leave", "Sick Leave"
    description = Column(Text, nullable=True)

    # Accrual configuration
    accrual_amount = Column(Float, default=0.0)    # Days added per period (e.g. 2.5 for monthly)
    accrual_frequency = Column(Enum(AccrualFrequency), default=AccrualFrequency.MONTHLY)
    max_balance = Column(Float, nullable=True)      # Cap on accumulated balance (null = unlimited)

    # Carry-forward policy
    carry_forward_enabled = Column(Boolean, default=False)
    carry_forward_max = Column(Float, nullable=True)  # Max days carried into next year

    # Encashment policy
    encashable = Column(Boolean, default=False)     # Can unused leave be converted to cash?
    encashment_rate = Column(Float, default=1.0)    # Multiplier on daily salary (1.0 = 1 day salary per leave day)

    # Is this leave paid? (unpaid leave = false)
    is_paid = Column(Boolean, default=True)

    # Approval config
    requires_approval = Column(Boolean, default=True)
    approval_levels = Column(Integer, default=1)   # 1 = direct manager, 2 = manager + HR, etc.

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class LeaveBalance(Base):
    """Tracks each employee's leave balance per leave type.

    Updated when:
    - Accrual runs (periodic job)
    - Leave request is approved (balance decreases)
    - Leave is cancelled/rejected (balance restored)
    - Year-end carry-forward
    """
    __tablename__ = "leave_balances"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )
    leave_type_id = Column(
        String(36), ForeignKey("leave_types.id", ondelete="CASCADE"), nullable=False, index=True
    )
    year = Column(Integer, nullable=False)  # e.g. 2026

    # Current available balance
    balance = Column(Float, default=0.0)

    # Carry-forward from previous year
    carried_forward = Column(Float, default=0.0)

    # Total accrued this year
    accrued = Column(Float, default=0.0)

    # Total used this year
    used = Column(Float, default=0.0)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", backref="leave_balances")
    leave_type = relationship("LeaveType", backref="balances")


class ApprovalStatus(str, enum.Enum):
    """Status of individual approval step in multi-level workflow."""
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    SKIPPED = "SKIPPED"  # When fewer levels are needed


class LeaveApprovalStep(Base):
    """Tracks each step in a multi-level approval workflow.

    Level 1 = direct manager
    Level 2 = HR / department head
    Level 3 = admin / executive
    """
    __tablename__ = "leave_approval_steps"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    leave_request_id = Column(
        String(36), ForeignKey("leaves.id", ondelete="CASCADE"), nullable=False, index=True
    )
    level = Column(Integer, nullable=False)  # 1, 2, 3...

    approver_id = Column(
        String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True
    )
    status = Column(Enum(ApprovalStatus), default=ApprovalStatus.PENDING, nullable=False)
    comments = Column(Text, nullable=True)
    acted_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    leave_request = relationship("LeaveModel", backref="approval_steps")
    approver = relationship("Employee", foreign_keys=[approver_id])


class LeaveEncashment(Base):
    """Request to convert unused leave balance to cash.

    Encashment rate is defined on the LeaveType.
    Calculated as: days_encashed * encashment_rate * daily_salary
    """
    __tablename__ = "leave_encashments"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )
    leave_type_id = Column(
        String(36), ForeignKey("leave_types.id", ondelete="CASCADE"), nullable=False
    )

    days_encashed = Column(Float, nullable=False)
    amount = Column(Float, nullable=False)          # Calculated payout
    daily_salary = Column(Float, nullable=False)    # Employee's daily salary at time of request

    status = Column(Enum(ApprovalStatus), default=ApprovalStatus.PENDING, nullable=False)
    processed_by = Column(
        String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True
    )
    processed_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="encashments")
    leave_type = relationship("LeaveType")
    processor = relationship("Employee", foreign_keys=[processed_by])
