"""
Reports & Analytics API:

- Headcount report (by department, by status, by role)
- Turnover rate report (hires vs exits per period)
- Attendance summary report
- Payroll summary report
- Leave summary report
- Custom report builder with Excel/PDF export
"""
import csv
import io
from datetime import datetime, date, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, extract, and_

from app.core.database import get_db
from app.models.models import Employee, Department, RoleEnum
from app.models.employee_enhanced import EmployeeStatus
from app.models.attendance import AttendanceModel
from app.models.leave import LeaveModel, LeaveStatus
from app.models.payroll import PayrollModel, PayrollStatus
from app.api.auth import get_current_user

router = APIRouter(prefix="/reports", tags=["Reports & Analytics"])

# ── Helpers ────────────────────────────────────────────────────

def _role(user) -> str:
    return user.role.value if hasattr(user.role, "value") else user.role


def _require_admin_or_manager(user):
    role = _role(user)
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can view reports",
        )


def _generate_csv(data: List[dict], headers: List[str]) -> bytes:
    """Generate CSV bytes from a list of dicts."""
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=headers, extrasaction="ignore")
    writer.writeheader()
    for row in data:
        writer.writerow(row)
    output.seek(0)
    return output.getvalue().encode("utf-8")


# ─── Headcount Report ──────────────────────────────────────────

@router.get("/headcount")
def headcount_report(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get headcount breakdown by department, role, and status."""
    _require_admin_or_manager(current_user)

    # Total active employees
    total = db.query(Employee).filter(Employee.is_active == True).count()

    # By role
    by_role = {}
    for role in RoleEnum:
        count = db.query(Employee).filter(
            Employee.role == role, Employee.is_active == True
        ).count()
        by_role[role.value] = count

    # By department
    by_department = {}
    departments = db.query(Department).all()
    for dept in departments:
        count = db.query(Employee).filter(
            Employee.department_id == dept.id, Employee.is_active == True
        ).count()
        by_department[dept.name] = count

    # By status (lifecycle)
    by_status = {}
    for status_val in EmployeeStatus:
        count = db.query(Employee).filter(Employee.status == status_val).count()
        by_status[status_val.value] = count

    # By gender (if we had the field — skipping for now)

    return {
        "total_active": total,
        "by_role": by_role,
        "by_department": by_department,
        "by_status": by_status,
    }


@router.get("/headcount/export")
def export_headcount(
    format: str = "csv",
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Export headcount report as CSV."""
    _require_admin_or_manager(current_user)

    report = headcount_report(current_user, db)

    # Flatten into rows
    rows = []
    for category, data in [("by_role", report["by_role"]),
                           ("by_department", report["by_department"]),
                           ("by_status", report["by_status"])]:
        for key, value in data.items():
            rows.append({"category": category, "group": key, "count": value})
    rows.insert(0, {"category": "total", "group": "total_active", "count": report["total_active"]})

    csv_bytes = _generate_csv(rows, ["category", "group", "count"])
    return StreamingResponse(
        io.BytesIO(csv_bytes),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=headcount_report.csv"}
    )


# ─── Turnover Report ───────────────────────────────────────────

@router.get("/turnover")
def turnover_report(
    year: int = Query(..., description="Year for the report, e.g. 2026"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get turnover rate for a given year.
    
    Turnover rate = (exits / average headcount) * 100
    """
    _require_admin_or_manager(current_user)

    # Count employees who exited in this year
    exits = db.query(Employee).filter(
        Employee.exit_date.isnot(None),
        extract("year", Employee.exit_date) == year,
    ).count()

    # Count employees hired in this year
    hires = db.query(Employee).filter(
        Employee.hire_date.isnot(None),
        extract("year", Employee.hire_date) == year,
    ).count()

    # Average headcount (start + end) / 2
    start_count = db.query(Employee).filter(
        Employee.hire_date < date(year, 1, 1),
    ).count()
    end_count = start_count + hires - exits
    avg_headcount = (start_count + end_count) / 2

    turnover_rate = (exits / avg_headcount * 100) if avg_headcount > 0 else 0

    # Monthly breakdown
    monthly = {}
    for month in range(1, 13):
        month_exits = db.query(Employee).filter(
            Employee.exit_date.isnot(None),
            extract("year", Employee.exit_date) == year,
            extract("month", Employee.exit_date) == month,
        ).count()
        month_hires = db.query(Employee).filter(
            Employee.hire_date.isnot(None),
            extract("year", Employee.hire_date) == year,
            extract("month", Employee.hire_date) == month,
        ).count()
        monthly[f"{year}-{month:02d}"] = {"hires": month_hires, "exits": month_exits}

    return {
        "year": year,
        "start_headcount": start_count,
        "hires": hires,
        "exits": exits,
        "end_headcount": end_count,
        "avg_headcount": avg_headcount,
        "turnover_rate": round(turnover_rate, 2),
        "monthly": monthly,
    }


# ─── Attendance Summary Report ─────────────────────────────────

@router.get("/attendance")
def attendance_report(
    start_date: str = Query(..., description="YYYY-MM-DD"),
    end_date: str = Query(..., description="YYYY-MM-DD"),
    employee_id: Optional[str] = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get attendance summary for a date range."""
    _require_admin_or_manager(current_user)

    start = datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.strptime(end_date, "%Y-%m-%d").date()

    query = db.query(AttendanceModel).filter(
        AttendanceModel.date >= start_date,
        AttendanceModel.date <= end_date,
    )
    if employee_id:
        query = query.filter(AttendanceModel.employee_id == employee_id)

    records = query.all()

    by_status = {}
    for r in records:
        by_status[r.status] = by_status.get(r.status, 0) + 1

    # Per-employee summary
    by_employee = {}
    for r in records:
        if r.employee_id not in by_employee:
            emp = db.query(Employee).filter(Employee.id == r.employee_id).first()
            by_employee[r.employee_id] = {
                "employee_id": r.employee_id,
                "employee_name": f"{emp.first_name} {emp.last_name}" if emp else "Unknown",
                "present": 0, "late": 0, "absent": 0, "total_days": 0,
            }
        by_employee[r.employee_id]["total_days"] += 1
        if r.status == "PRESENT":
            by_employee[r.employee_id]["present"] += 1
        elif r.status == "LATE":
            by_employee[r.employee_id]["late"] += 1
        elif r.status == "ABSENT":
            by_employee[r.employee_id]["absent"] += 1

    return {
        "start_date": start_date,
        "end_date": end_date,
        "total_records": len(records),
        "by_status": by_status,
        "by_employee": list(by_employee.values()),
    }


@router.get("/attendance/export")
def export_attendance_report(
    start_date: str = Query(..., description="YYYY-MM-DD"),
    end_date: str = Query(..., description="YYYY-MM-DD"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Export attendance report as CSV."""
    _require_admin_or_manager(current_user)

    report = attendance_report(start_date, end_date, None, current_user, db)
    csv_bytes = _generate_csv(report["by_employee"], ["employee_id", "employee_name", "present", "late", "absent", "total_days"])
    return StreamingResponse(
        io.BytesIO(csv_bytes),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=attendance_report_{start_date}_{end_date}.csv"}
    )


# ─── Payroll Summary Report ───────────────────────────────────

@router.get("/payroll")
def payroll_summary_report(
    month_year: str = Query(..., description="e.g. '2026-11'"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get payroll summary for a given month."""
    _require_admin_or_manager(current_user)

    payrolls = db.query(PayrollModel).filter(PayrollModel.month_year == month_year).all()

    total_gross = sum(p.base_salary + p.bonus for p in payrolls)
    total_deductions = sum(p.deductions for p in payrolls)
    total_net = sum(p.net_salary for p in payrolls)

    by_status = {}
    for p in payrolls:
        status = p.status.value if hasattr(p.status, "value") else str(p.status)
        by_status[status] = by_status.get(status, 0) + 1

    return {
        "month_year": month_year,
        "total_records": len(payrolls),
        "total_gross": total_gross,
        "total_deductions": total_deductions,
        "total_net": total_net,
        "by_status": by_status,
    }


@router.get("/payroll/export")
def export_payroll_report(
    month_year: str = Query(..., description="e.g. '2026-11'"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Export payroll report as CSV."""
    _require_admin_or_manager(current_user)

    payrolls = db.query(PayrollModel).filter(PayrollModel.month_year == month_year).all()

    rows = []
    for p in payrolls:
        emp = db.query(Employee).filter(Employee.id == p.employee_id).first()
        rows.append({
            "payroll_id": p.id,
            "employee_name": f"{emp.first_name} {emp.last_name}" if emp else "Unknown",
            "employee_email": emp.email if emp else "",
            "month_year": p.month_year,
            "base_salary": p.base_salary,
            "bonus": p.bonus,
            "deductions": p.deductions,
            "net_salary": p.net_salary,
            "status": p.status.value if hasattr(p.status, "value") else str(p.status),
        })

    csv_bytes = _generate_csv(rows, ["payroll_id", "employee_name", "employee_email", "month_year", "base_salary", "bonus", "deductions", "net_salary", "status"])
    return StreamingResponse(
        io.BytesIO(csv_bytes),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=payroll_report_{month_year}.csv"}
    )


# ─── Leave Summary Report ───────────────────────────────────────

@router.get("/leave")
def leave_summary_report(
    year: int = Query(..., description="Year for the report"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get leave summary for a given year."""
    _require_admin_or_manager(current_user)

    leaves = db.query(LeaveModel).filter(
        extract("year", LeaveModel.start_date) == year,
    ).all()

    by_status = {}
    by_type = {}
    for l in leaves:
        status = l.status.value if hasattr(l.status, "value") else str(l.status)
        by_status[status] = by_status.get(status, 0) + 1
        by_type[l.leave_type] = by_type.get(l.leave_type, 0) + 1

    return {
        "year": year,
        "total_requests": len(leaves),
        "by_status": by_status,
        "by_type": by_type,
    }


# ─── Custom Report Builder ─────────────────────────────────────

@router.get("/custom")
def custom_report(
    entity: str = Query(..., description="employees, attendance, payroll, leaves"),
    format: str = Query("json", description="json or csv"),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Custom report builder — export raw data by entity type as CSV or JSON.
    
    Available entities: employees, attendance, payroll, leaves
    """
    _require_admin_or_manager(current_user)

    if entity == "employees":
        records = db.query(Employee).all()
        rows = []
        for e in records:
            rows.append({
                "id": e.id,
                "first_name": e.first_name,
                "last_name": e.last_name,
                "email": e.email,
                "position": e.position or "",
                "role": e.role.value if hasattr(e.role, "value") else str(e.role),
                "is_active": e.is_active,
                "status": e.status.value if hasattr(e.status, "value") else str(e.status),
                "hire_date": e.hire_date.strftime("%Y-%m-%d") if e.hire_date else "",
            })
        headers = ["id", "first_name", "last_name", "email", "position", "role", "is_active", "status", "hire_date"]

    elif entity == "attendance":
        records = db.query(AttendanceModel).all()
        rows = []
        for a in records:
            emp = db.query(Employee).filter(Employee.id == a.employee_id).first()
            rows.append({
                "id": a.id,
                "employee_id": a.employee_id,
                "employee_name": f"{emp.first_name} {emp.last_name}" if emp else "",
                "date": a.date,
                "check_in": a.check_in_time.strftime("%H:%M") if a.check_in_time else "",
                "check_out": a.check_out_time.strftime("%H:%M") if a.check_out_time else "",
                "status": a.status,
            })
        headers = ["id", "employee_id", "employee_name", "date", "check_in", "check_out", "status"]

    elif entity == "payroll":
        records = db.query(PayrollModel).all()
        rows = []
        for p in records:
            emp = db.query(Employee).filter(Employee.id == p.employee_id).first()
            rows.append({
                "id": p.id,
                "employee_name": f"{emp.first_name} {emp.last_name}" if emp else "",
                "month_year": p.month_year,
                "base_salary": p.base_salary,
                "bonus": p.bonus,
                "deductions": p.deductions,
                "net_salary": p.net_salary,
                "status": p.status.value if hasattr(p.status, "value") else str(p.status),
            })
        headers = ["id", "employee_name", "month_year", "base_salary", "bonus", "deductions", "net_salary", "status"]

    elif entity == "leaves":
        records = db.query(LeaveModel).all()
        rows = []
        for l in records:
            emp = db.query(Employee).filter(Employee.id == l.employee_id).first()
            rows.append({
                "id": l.id,
                "employee_name": f"{emp.first_name} {emp.last_name}" if emp else "",
                "leave_type": l.leave_type,
                "start_date": l.start_date.strftime("%Y-%m-%d") if l.start_date else "",
                "end_date": l.end_date.strftime("%Y-%m-%d") if l.end_date else "",
                "status": l.status.value if hasattr(l.status, "value") else str(l.status),
            })
        headers = ["id", "employee_name", "leave_type", "start_date", "end_date", "status"]

    else:
        raise HTTPException(status_code=422, detail=f"Unknown entity: {entity}. Use: employees, attendance, payroll, leaves")

    if format == "csv":
        csv_bytes = _generate_csv(rows, headers)
        return StreamingResponse(
            io.BytesIO(csv_bytes),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename={entity}_report.csv"}
        )

    return {"entity": entity, "total_records": len(rows), "data": rows}
