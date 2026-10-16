from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class AttendanceModel(Base):
  __tablename__ = "attendances"

  id = Column(Integer, primary_key=True, index=True)
  employee_id = Column(
      String(36), ForeignKey("employees.id", ondelete="CASCADE")
  )
  date = Column(
      String(10), nullable=False
  )  # ថ្ងៃខែឆ្នាំ (YYYY-MM-DD) សម្រាប់ផ្ទៀងផ្ទាត់ 1 ថ្ងៃ 1 ដង
  check_in_time = Column(DateTime(timezone=True), nullable=True)
  check_out_time = Column(DateTime(timezone=True), nullable=True)
  status = Column(
      String(20), default="PRESENT", nullable=False
  )  # PRESENT, LATE, ABSENT

  # ជួសជុល: ឈ្មោះ class គឺ Employee មិនមែន EmployeeModel
  employee = relationship("Employee", backref="attendances")
