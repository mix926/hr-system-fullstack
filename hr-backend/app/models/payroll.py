import enum
from sqlalchemy import Column, DateTime, Enum, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class PayrollStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    CANCELLED = "CANCELLED"


class PayrollModel(Base):
    __tablename__ = "payrolls"

    id = Column(Integer, primary_key=True, index=True)
    # Employee.id is a UUID String(36), so ForeignKey type must also be String
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )
    month_year = Column(String(7), nullable=False)  # e.g. "2026-10"
    base_salary = Column(Float, nullable=False, default=0.0)
    bonus = Column(Float, nullable=False, default=0.0)
    deductions = Column(Float, nullable=False, default=0.0)
    net_salary = Column(Float, nullable=False, default=0.0)
    status = Column(
        Enum(PayrollStatus), default=PayrollStatus.PENDING, nullable=False
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationship back to Employee
    employee = relationship("Employee", backref="payrolls")
