# Location: app/models/payroll.py
from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class PayrollModel(Base):
  __tablename__ = "payrolls"

  id = Column(Integer, primary_key=True, index=True)
  # Employee.id is a UUID String(36), so ForeignKey type must also be String
  employee_id = Column(
      String(36), ForeignKey("employees.id", ondelete="CASCADE")
  )
  month_year = Column(
      String, nullable=False
  )  # ឧទាហរណ៍: "2026-10" (ខែ និងឆ្នាំ)
  base_salary = Column(Float, nullable=False, default=0.0)
  bonus = Column(Float, nullable=False, default=0.0)
  deductions = Column(Float, nullable=False, default=0.0)
  net_salary = Column(Float, nullable=False, default=0.0)
  status = Column(
      String, default="PENDING", nullable=False
  )  # PENDING, PAID
  created_at = Column(DateTime(timezone=True), server_default=func.now())

  # Must reference the class name "Employee" from models/models.py
  employee = relationship("Employee", backref="payrolls")