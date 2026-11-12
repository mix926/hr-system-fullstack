"""
Payroll Enhancement schemas:
- SalaryStructure CRUD
- Payslip line items
- Tax bracket management
- Payslip PDF and bank file generation requests
"""
from datetime import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, Field
from app.models.payroll_enhanced import SalaryComponentType


# ─── Salary Component (sub-schema for allowances/deductions) ───

class SalaryComponent(BaseModel):
    """A single allowance or deduction entry."""
    name: str
    amount: float = Field(0.0, ge=0)     # Used when type="fixed"
    rate: float = Field(0.0, ge=0)       # Used when type="percentage" (percentage of base_salary)
    type: str = "fixed"                   # "fixed" or "percentage"


class StatutoryContribution(BaseModel):
    """Statutory contribution (social security, pension, etc.)."""
    name: str
    employee_rate: float = Field(0.0, ge=0)  # % deducted from employee
    employer_rate: float = Field(0.0, ge=0)  # % paid by employer


# ─── SalaryStructure Schemas ──────────────────────────────────

class SalaryStructureBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    designation_id: Optional[str] = None
    grade: Optional[str] = None
    base_salary: float = Field(..., ge=0)
    allowances: List[SalaryComponent] = []
    deductions: List[SalaryComponent] = []
    statutory_contributions: List[StatutoryContribution] = []
    gratuity_enabled: bool = False
    gratuity_rate: float = Field(0.0, ge=0)
    is_active: bool = True


class SalaryStructureCreate(SalaryStructureBase):
    pass


class SalaryStructureUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    designation_id: Optional[str] = None
    grade: Optional[str] = None
    base_salary: Optional[float] = Field(None, ge=0)
    allowances: Optional[List[SalaryComponent]] = None
    deductions: Optional[List[SalaryComponent]] = None
    statutory_contributions: Optional[List[StatutoryContribution]] = None
    gratuity_enabled: Optional[bool] = None
    gratuity_rate: Optional[float] = Field(None, ge=0)
    is_active: Optional[bool] = None


class SalaryStructureResponse(SalaryStructureBase):
    id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Payslip Line Item Schemas ─────────────────────────────────

class PayslipLineItemResponse(BaseModel):
    id: int
    payroll_id: int
    component_type: SalaryComponentType
    name: str
    amount: float
    is_statutory: bool
    created_at: datetime

    class Config:
        from_attributes = True


class PayslipDetailResponse(BaseModel):
    """Full payslip with line items — used for PDF generation."""
    payroll_id: int
    employee_id: str
    employee_name: str
    employee_email: str
    employee_position: Optional[str] = None
    month_year: str
    earnings: List[PayslipLineItemResponse] = []
    deductions: List[PayslipLineItemResponse] = []
    gross_earnings: float
    total_deductions: float
    net_salary: float
    status: str
    created_at: Optional[datetime] = None


# ─── Tax Bracket Schemas ──────────────────────────────────────

class TaxBracketBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    min_amount: float = Field(0.0, ge=0)
    max_amount: Optional[float] = None
    rate: float = Field(..., ge=0, le=100)  # Percentage
    is_active: bool = True


class TaxBracketCreate(TaxBracketBase):
    pass


class TaxBracketUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    min_amount: Optional[float] = Field(None, ge=0)
    max_amount: Optional[float] = None
    rate: Optional[float] = Field(None, ge=0, le=100)
    is_active: Optional[bool] = None


class TaxBracketResponse(TaxBracketBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Payslip Generation Request ───────────────────────────────

class GeneratePayrollRequest(BaseModel):
    """Generate payroll for an employee using their salary structure."""
    employee_id: str
    month_year: str = Field(..., description="e.g. '2026-11'")
    salary_structure_id: str
    bonus: float = Field(0.0, ge=0)
    overtime_pay: float = Field(0.0, ge=0)


class BankFileRequest(BaseModel):
    """Request bank file for salary transfer."""
    month_year: str = Field(..., description="e.g. '2026-11'")
    bank_name: Optional[str] = None
    account_format: str = Field("csv", description="csv or txt")
