"""
Payroll Enhancement API:

- SalaryStructure CRUD (grade-based salary templates)
- TaxBracket CRUD (progressive tax brackets)
- Generate payroll from a salary structure (creates line items)
- Payslip PDF download
- Bank file generation (CSV) for salary transfer
- End-of-service gratuity calculation
"""
import csv
import io
import os
from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import Employee
from app.models.payroll import PayrollModel, PayrollStatus
from app.models.payroll_enhanced import (
    SalaryStructure,
    PayslipLineItem,
    SalaryComponentType,
    TaxBracket,
)
from app.schemas.payroll_enhanced import (
    SalaryStructureCreate,
    SalaryStructureUpdate,
    SalaryStructureResponse,
    PayslipLineItemResponse,
    PayslipDetailResponse,
    TaxBracketCreate,
    TaxBracketUpdate,
    TaxBracketResponse,
    GeneratePayrollRequest,
    BankFileRequest,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/payroll", tags=["Payroll Management"])

# ── Helpers ────────────────────────────────────────────────────

def _role(user) -> str:
    return user.role.value if hasattr(user.role, "value") else user.role


def _require_admin(user):
    if _role(user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can perform this action",
        )


def _require_admin_or_manager(user):
    role = _role(user)
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can perform this action",
        )


def _calc_component_amount(component: dict, base_salary: float) -> float:
    """Calculate a component amount — supports fixed and percentage types."""
    if component.get("type") == "percentage":
        return base_salary * (component.get("rate", 0) / 100.0)
    return component.get("amount", 0)


def _calc_tax(taxable_income: float, db: Session) -> float:
    """Calculate progressive tax using active tax brackets."""
    brackets = db.query(TaxBracket).filter(
        TaxBracket.is_active == True
    ).order_by(TaxBracket.min_amount.asc()).all()

    total_tax = 0.0
    remaining = taxable_income
    for bracket in brackets:
        bracket_max = bracket.max_amount if bracket.max_amount else float('inf')
        if remaining <= 0:
            break
        bracket_range = bracket_max - bracket.min_amount
        taxable_in_bracket = min(remaining, bracket_range)
        total_tax += taxable_in_bracket * (bracket.rate / 100.0)
        remaining -= taxable_in_bracket

    return total_tax


def _calc_gratuity(base_salary: float, hire_date: Optional[datetime], gratuity_rate: float) -> float:
    """Calculate end-of-service gratuity based on years of service.
    
    gratuity_rate = days of salary per year of service
    """
    if not hire_date or gratuity_rate <= 0:
        return 0.0
    years = (date.today() - hire_date.date()).days / 365.25
    daily_salary = base_salary / 30  # Assuming 30-day month
    return daily_salary * gratuity_rate * years


def _generate_payslip_pdf(payslip_data: dict) -> bytes:
    """Generate a PDF payslip using reportlab."""
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import mm
    from reportlab.platypus import (
        SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
    )

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm)
    styles = getSampleStyleSheet()
    elements = []

    # Title
    title_style = ParagraphStyle('CustomTitle', parent=styles['Title'], fontSize=18, spaceAfter=10)
    elements.append(Paragraph("Payslip", title_style))
    elements.append(HRFlowable(width="100%", thickness=1, color=colors.grey))
    elements.append(Spacer(1, 10))

    # Employee info
    info_data = [
        ["Employee:", payslip_data.get("employee_name", "")],
        ["Email:", payslip_data.get("employee_email", "")],
        ["Position:", payslip_data.get("employee_position", "N/A")],
        ["Pay Period:", payslip_data.get("month_year", "")],
        ["Status:", payslip_data.get("status", "")],
    ]
    info_table = Table(info_data, colWidths=[40*mm, 120*mm])
    info_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    elements.append(info_table)
    elements.append(Spacer(1, 15))

    # Earnings table
    elements.append(Paragraph("<b>Earnings</b>", styles['Normal']))
    earnings_data = [["Description", "Amount"]]
    for item in payslip_data.get("earnings", []):
        earnings_data.append([item["name"], f"{item['amount']:.2f}"])
    earnings_data.append(["", ""])
    earnings_data.append(["Gross Earnings:", f"{payslip_data.get('gross_earnings', 0):.2f}"])
    earnings_table = Table(earnings_data, colWidths=[120*mm, 50*mm])
    earnings_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('LINEBELOW', (0, 0), (-1, 0), 0.5, colors.grey),
        ('LINEABOVE', (0, -1), (-1, -1), 0.5, colors.grey),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
    ]))
    elements.append(earnings_table)
    elements.append(Spacer(1, 10))

    # Deductions table
    elements.append(Paragraph("<b>Deductions</b>", styles['Normal']))
    deductions_data = [["Description", "Amount"]]
    for item in payslip_data.get("deductions", []):
        deductions_data.append([item["name"], f"{item['amount']:.2f}"])
    deductions_data.append(["", ""])
    deductions_data.append(["Total Deductions:", f"{payslip_data.get('total_deductions', 0):.2f}"])
    deductions_table = Table(deductions_data, colWidths=[120*mm, 50*mm])
    deductions_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('LINEBELOW', (0, 0), (-1, 0), 0.5, colors.grey),
        ('LINEABOVE', (0, -1), (-1, -1), 0.5, colors.grey),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
    ]))
    elements.append(deductions_table)
    elements.append(Spacer(1, 15))

    # Net salary
    net_style = ParagraphStyle('NetSalary', parent=styles['Normal'], fontSize=14, fontName='Helvetica-Bold')
    net_table = Table([
        ["Net Salary:", f"{payslip_data.get('net_salary', 0):.2f}"]
    ], colWidths=[120*mm, 50*mm])
    net_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 12),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.white),
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#2E86AB')),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    elements.append(net_table)
    elements.append(Spacer(1, 20))
    elements.append(Paragraph(
        f"<i>Generated on {datetime.now().strftime('%Y-%m-%d %H:%M')}</i>",
        ParagraphStyle('Footer', parent=styles['Normal'], fontSize=8, textColor=colors.grey)
    ))

    doc.build(elements)
    buffer.seek(0)
    return buffer.getvalue()


# ─── Salary Structure CRUD ────────────────────────────────────

@router.get("/structures", response_model=List[SalaryStructureResponse])
def get_salary_structures(
    active_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all salary structures."""
    query = db.query(SalaryStructure)
    if active_only:
        query = query.filter(SalaryStructure.is_active == True)
    return query.all()


@router.post("/structures", response_model=SalaryStructureResponse, status_code=status.HTTP_201_CREATED)
def create_salary_structure(
    body: SalaryStructureCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a salary structure. ADMIN only."""
    _require_admin(current_user)
    existing = db.query(SalaryStructure).filter(SalaryStructure.name == body.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Salary structure already exists")
    structure = SalaryStructure(**body.model_dump())
    db.add(structure)
    db.commit()
    db.refresh(structure)
    return structure


@router.patch("/structures/{structure_id}", response_model=SalaryStructureResponse)
def update_salary_structure(
    structure_id: str,
    body: SalaryStructureUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a salary structure. ADMIN only."""
    _require_admin(current_user)
    structure = db.query(SalaryStructure).filter(SalaryStructure.id == structure_id).first()
    if not structure:
        raise HTTPException(status_code=404, detail="Salary structure not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(structure, key, value)
    db.commit()
    db.refresh(structure)
    return structure


@router.delete("/structures/{structure_id}")
def delete_salary_structure(
    structure_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a salary structure. ADMIN only."""
    _require_admin(current_user)
    structure = db.query(SalaryStructure).filter(SalaryStructure.id == structure_id).first()
    if not structure:
        raise HTTPException(status_code=404, detail="Salary structure not found")
    structure.is_active = False
    db.commit()
    return {"message": "Salary structure deactivated"}


# ─── Tax Bracket CRUD ─────────────────────────────────────────

@router.get("/tax-brackets", response_model=List[TaxBracketResponse])
def get_tax_brackets(
    active_only: bool = False,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all tax brackets."""
    query = db.query(TaxBracket)
    if active_only:
        query = query.filter(TaxBracket.is_active == True)
    return query.order_by(TaxBracket.min_amount.asc()).all()


@router.post("/tax-brackets", response_model=TaxBracketResponse, status_code=status.HTTP_201_CREATED)
def create_tax_bracket(
    body: TaxBracketCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a tax bracket. ADMIN only."""
    _require_admin(current_user)
    bracket = TaxBracket(**body.model_dump())
    db.add(bracket)
    db.commit()
    db.refresh(bracket)
    return bracket


@router.patch("/tax-brackets/{bracket_id}", response_model=TaxBracketResponse)
def update_tax_bracket(
    bracket_id: int,
    body: TaxBracketUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a tax bracket. ADMIN only."""
    _require_admin(current_user)
    bracket = db.query(TaxBracket).filter(TaxBracket.id == bracket_id).first()
    if not bracket:
        raise HTTPException(status_code=404, detail="Tax bracket not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(bracket, key, value)
    db.commit()
    db.refresh(bracket)
    return bracket


@router.delete("/tax-brackets/{bracket_id}")
def delete_tax_bracket(
    bracket_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a tax bracket. ADMIN only."""
    _require_admin(current_user)
    bracket = db.query(TaxBracket).filter(TaxBracket.id == bracket_id).first()
    if not bracket:
        raise HTTPException(status_code=404, detail="Tax bracket not found")
    db.delete(bracket)
    db.commit()
    return {"message": "Tax bracket deleted"}


# ─── Generate Payroll from Salary Structure ───────────────────

@router.post("/generate", response_model=PayslipDetailResponse, status_code=status.HTTP_201_CREATED)
def generate_payroll(
    body: GeneratePayrollRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Generate a payroll record from a salary structure.
    
    Creates line items for base salary, each allowance, each deduction,
    statutory contributions, and tax. ADMIN only.
    """
    _require_admin(current_user)

    emp = db.query(Employee).filter(Employee.id == body.employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    structure = db.query(SalaryStructure).filter(SalaryStructure.id == body.salary_structure_id).first()
    if not structure:
        raise HTTPException(status_code=404, detail="Salary structure not found")

    # Calculate gross earnings
    gross = structure.base_salary + body.bonus + body.overtime_pay
    line_items = []

    # Base salary line item
    line_items.append(PayslipLineItem(
        payroll_id=0,  # Will be set after payroll is created
        component_type=SalaryComponentType.EARNING,
        name="Base Salary",
        amount=structure.base_salary,
        is_statutory=False,
    ))

    # Bonus
    if body.bonus > 0:
        line_items.append(PayslipLineItem(
            payroll_id=0,
            component_type=SalaryComponentType.EARNING,
            name="Bonus",
            amount=body.bonus,
            is_statutory=False,
        ))

    # Overtime pay
    if body.overtime_pay > 0:
        line_items.append(PayslipLineItem(
            payroll_id=0,
            component_type=SalaryComponentType.EARNING,
            name="Overtime Pay",
            amount=body.overtime_pay,
            is_statutory=False,
        ))

    # Allowances
    for allowance in (structure.allowances or []):
        amt = _calc_component_amount(allowance, structure.base_salary)
        if amt > 0:
            gross += amt
            line_items.append(PayslipLineItem(
                payroll_id=0,
                component_type=SalaryComponentType.EARNING,
                name=allowance.get("name", "Allowance"),
                amount=amt,
                is_statutory=False,
            ))

    # Statutory contributions (employee portion)
    total_deductions = 0.0
    for contribution in (structure.statutory_contributions or []):
        emp_rate = contribution.get("employee_rate", 0)
        if emp_rate > 0:
            amt = structure.base_salary * (emp_rate / 100.0)
            total_deductions += amt
            line_items.append(PayslipLineItem(
                payroll_id=0,
                component_type=SalaryComponentType.DEDUCTION,
                name=contribution.get("name", "Statutory Contribution"),
                amount=amt,
                is_statutory=True,
            ))

    # Other deductions
    for deduction in (structure.deductions or []):
        amt = _calc_component_amount(deduction, structure.base_salary)
        if amt > 0:
            total_deductions += amt
            line_items.append(PayslipLineItem(
                payroll_id=0,
                component_type=SalaryComponentType.DEDUCTION,
                name=deduction.get("name", "Deduction"),
                amount=amt,
                is_statutory=False,
            ))

    # Calculate tax
    taxable_income = gross - total_deductions
    tax = _calc_tax(taxable_income, db)
    if tax > 0:
        total_deductions += tax
        line_items.append(PayslipLineItem(
            payroll_id=0,
            component_type=SalaryComponentType.DEDUCTION,
            name="Income Tax",
            amount=tax,
            is_statutory=True,
        ))

    net_salary = gross - total_deductions

    # Create payroll record
    payroll = PayrollModel(
        employee_id=body.employee_id,
        month_year=body.month_year,
        base_salary=structure.base_salary,
        bonus=body.bonus,
        deductions=total_deductions,
        net_salary=net_salary,
        status=PayrollStatus.PENDING,
    )
    db.add(payroll)
    db.commit()
    db.refresh(payroll)

    # Update line items with payroll_id and save
    for item in line_items:
        item.payroll_id = payroll.id
        db.add(item)
    db.commit()

    # Return detailed payslip
    return _build_payslip_detail(payroll, emp, db)


def _build_payslip_detail(payroll: PayrollModel, employee: Employee, db: Session) -> PayslipDetailResponse:
    """Build a PayslipDetailResponse from a payroll record."""
    line_items = db.query(PayslipLineItem).filter(PayslipLineItem.payroll_id == payroll.id).all()
    earnings = [li for li in line_items if li.component_type == SalaryComponentType.EARNING]
    deductions = [li for li in line_items if li.component_type == SalaryComponentType.DEDUCTION]
    gross = sum(e.amount for e in earnings)
    total_ded = sum(d.amount for d in deductions)

    return PayslipDetailResponse(
        payroll_id=payroll.id,
        employee_id=employee.id,
        employee_name=f"{employee.first_name} {employee.last_name}",
        employee_email=employee.email,
        employee_position=employee.position,
        month_year=payroll.month_year,
        earnings=[PayslipLineItemResponse.model_validate(e) for e in earnings],
        deductions=[PayslipLineItemResponse.model_validate(d) for d in deductions],
        gross_earnings=gross,
        total_deductions=total_ded,
        net_salary=payroll.net_salary,
        status=payroll.status.value if hasattr(payroll.status, "value") else payroll.status,
        created_at=payroll.created_at,
    )


# ─── Payslip Detail & PDF ─────────────────────────────────────

@router.get("/{payroll_id}/payslip", response_model=PayslipDetailResponse)
def get_payslip_detail(
    payroll_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get detailed payslip with line items. ADMIN/MANAGER see all; STAFF sees own only."""
    payroll = db.query(PayrollModel).filter(PayrollModel.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll record not found")
    if _role(current_user) == "STAFF" and payroll.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only view your own payslips")
    emp = db.query(Employee).filter(Employee.id == payroll.employee_id).first()
    return _build_payslip_detail(payroll, emp, db)


@router.get("/{payroll_id}/payslip/pdf")
def download_payslip_pdf(
    payroll_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Download a PDF payslip. ADMIN/MANAGER see all; STAFF sees own only."""
    payroll = db.query(PayrollModel).filter(PayrollModel.id == payroll_id).first()
    if not payroll:
        raise HTTPException(status_code=404, detail="Payroll record not found")
    if _role(current_user) == "STAFF" and payroll.employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only download your own payslips")
    emp = db.query(Employee).filter(Employee.id == payroll.employee_id).first()
    payslip = _build_payslip_detail(payroll, emp, db)
    pdf_bytes = _generate_payslip_pdf(payslip.model_dump())
    filename = f"payslip_{emp.first_name}_{emp.last_name}_{payroll.month_year}.pdf"
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# ─── Bank File Generation ──────────────────────────────────────

@router.post("/bank-file")
def generate_bank_file(
    body: BankFileRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Generate a bank file (CSV) for salary transfer.
    
    Includes all PAID payroll records for the specified month.
    ADMIN only.
    """
    _require_admin(current_user)

    payrolls = db.query(PayrollModel).filter(
        PayrollModel.month_year == body.month_year,
        PayrollModel.status == PayrollStatus.PAID,
    ).all()

    if not payrolls:
        raise HTTPException(status_code=404, detail=f"No paid payroll records for {body.month_year}")

    output = io.StringIO()
    writer = csv.writer(output)
    # Header row
    writer.writerow(["Employee ID", "Employee Name", "Email", "Month", "Net Salary", "Bank Account"])

    for p in payrolls:
        emp = db.query(Employee).filter(Employee.id == p.employee_id).first()
        writer.writerow([
            emp.id,
            f"{emp.first_name} {emp.last_name}" if emp else "Unknown",
            emp.email if emp else "",
            p.month_year,
            f"{p.net_salary:.2f}",
            "",  # Bank account — would come from employee bank details
        ])

    output.seek(0)
    filename = f"bank_file_{body.month_year}.csv"
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode("utf-8")),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# ─── End-of-Service / Gratuity ──────────────────────────────────

@router.get("/gratuity/{employee_id}")
def calculate_gratuity(
    employee_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Calculate end-of-service gratuity for an employee.
    
    Uses the latest salary structure assigned to the employee's designation.
    ADMIN/MANAGER can view for anyone; STAFF for self only.
    """
    if _role(current_user) == "STAFF" and employee_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")

    emp = db.query(Employee).filter(Employee.id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    # Find salary structure by designation
    structure = None
    if emp.designation_id:
        structure = db.query(SalaryStructure).filter(
            SalaryStructure.designation_id == emp.designation_id,
            SalaryStructure.is_active == True,
        ).first()

    if not structure or not structure.gratuity_enabled:
        return {
            "employee_id": employee_id,
            "gratuity_enabled": False,
            "gratuity_amount": 0.0,
            "message": "Gratuity not configured for this employee's grade"
        }

    gratuity = _calc_gratuity(structure.base_salary, emp.hire_date, structure.gratuity_rate)

    years = 0
    if emp.hire_date:
        years = (date.today() - emp.hire_date.date()).days / 365.25

    return {
        "employee_id": employee_id,
        "gratuity_enabled": True,
        "gratuity_rate": structure.gratuity_rate,
        "years_of_service": round(years, 2),
        "base_salary": structure.base_salary,
        "gratuity_amount": round(gratuity, 2),
    }
