import enum
from sqlalchemy import Column, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

# ខ្មែរ: ចូល Base ពី app.core.database (Absolute Import ត្រឹមត្រូវ)
from app.core.database import Base


class LeaveStatus(str, enum.Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class LeaveModel(Base):
    __tablename__ = "leaves"

    # ខ្មែរ: ប្រើ String(36) ជា Primary Key ដូចគ្នាទៅនឹង Employee model (UUID)
    id = Column(String(36), primary_key=True, index=True, default=lambda: __import__('uuid').uuid4().__str__())

    # ខ្មែរ: Foreign Key ត្រូវតែ String(36) ព្រោះ employees.id ជា UUID String
    employee_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False
    )
    leave_type = Column(String(50), nullable=False)  # e.g., Annual Leave, Sick Leave
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(
        Enum(LeaveStatus), default=LeaveStatus.PENDING, nullable=False
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # ខ្មែរ: ឈ្មោះ Class ត្រូវជា "Employee" (ដូចដែលកំណត់ក្នុង models.py)
    employee = relationship("Employee", backref="leaves")
