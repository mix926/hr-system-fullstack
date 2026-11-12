"""
Payroll Enhancement models:

- SalaryStructure: grade-based salary templates with allowances and deductions
- PayslipLineItem: detailed breakdown of earnings and deductions on a payslip
- TaxBracket: configurable progressive tax brackets
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text, Integer, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class SalaryComponentType(str, enum.Enum):
    """Whether a component adds to or subtracts from gross salary."""
    EARNING = "EARNING"        # Allowance, bonus, overtime pay
    DEDUCTION = "DEDUCTION"    # Tax, insurance, pension, loan


class SalaryStructure(Base):
    """Salary template linked to a designation grade.

    Defines the base salary and standard allowances/deductions that apply
    when an employee is assigned this structure. Stored as JSON arrays for
    flexibility.
    """
    __tablename__ = "salary_structures"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    name = Column(String(100), nullable=False, unique=True)  # e.g. "Engineer Grade L5"
    designation_id = Column(
        String(36), ForeignKey("designations.id", ondelete="SET NULL"), nullable=True
    )
    grade = Column(String(20), nullable=True)               # e.g. "L5", "M2"

    base_salary = Column(Float, nullable=False, default=0.0)

    # Allowances stored as JSON: [{"name": "Housing", "amount": 500, "type": "fixed"}]
    # type can be "fixed" (flat amount) or "percentage" (of base_salary)
    allowances = Column(JSON, nullable=True, default=list)

    # Deductions stored as JSON: [{"name": "Income Tax", "rate": 10, "type": "percentage"}]
    deductions = Column(JSON, nullable=True, default=list)

    # Statutory contributions (e.g., social security, pension)
    # Stored as JSON: [{"name": "Social Security", "employee_rate": 5, "employer_rate": 10}]
    statutory_contributions = Column(JSON, nullable=True, default=list)

    # End-of-service / gratuity configuration (important for Gulf region)
    gratuity_enabled = Column(Boolean, default=False)
    gratuity_rate = Column(Float, default=0.0)  # Days of salary per year of service

    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    designation = relationship("Designation")


class PayslipLineItem(Base):
    """Individual line item on a payslip — one row per earning or deduction.

    Linked to the payroll record for detailed breakdown.
    """
    __tablename__ = "payslip_line_items"

    id = Column(Integer, primary_key=True, index=True)
    payroll_id = Column(
        Integer, ForeignKey("payrolls.id", ondelete="CASCADE"), nullable=False, index=True
    )

    component_type = Column(Enum(SalaryComponentType), nullable=False)  # EARNING or DEDUCTION
    name = Column(String(100), nullable=False)          # "Base Salary", "Housing Allowance", "Income Tax"
    amount = Column(Float, nullable=False, default=0.0)
    is_statutory = Column(Boolean, default=False)       # True for tax/insurance/pension

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationship
    payroll = relationship("PayrollModel", backref="line_items")


class TaxBracket(Base):
    """Progressive tax bracket configuration.

    Applied sequentially: income within each bracket is taxed at that bracket's rate.
    """
    __tablename__ = "tax_brackets"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)          # "2026 Tax Table"
    min_amount = Column(Float, nullable=False, default=0.0)  # Lower bound of bracket
    max_amount = Column(Float, nullable=True)            # Upper bound (null = no limit)
    rate = Column(Float, nullable=False)               # Percentage rate (e.g. 10 = 10%)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
