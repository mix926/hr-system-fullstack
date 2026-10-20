from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import Optional
from pydantic import BaseModel
from app.repositories import crud
from app.schemas import schemas
from app.core.database import SessionLocal
from app.models.models import Employee
from app.api.auth import get_current_user

router = APIRouter(
    prefix="/employees",
    tags=["Employees"]
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ---- Schemas ----

class EmployeeUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name:  Optional[str] = None
    position:   Optional[str] = None
    department_id: Optional[str] = None

# 1. POST ROUTE (Create Employee) / ផ្លូវសម្រាប់បង្កើតបុគ្គលិក
@router.post("/", response_model=schemas.EmployeeResponse)
def create_new_employee(
    employee: schemas.EmployeeCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Create a new employee. Only authenticated users can access."""
    db_employee = crud.get_employee_by_email(db, email=employee.email)
    if db_employee:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_employee(db=db, employee=employee)

# 2. GET ALL ROUTE (Read Employees) / ផ្លូវសម្រាប់អានទិន្នន័យបុគ្គលិកទាំងអស់
@router.get("/", response_model=list[schemas.EmployeeResponse])
def read_employees(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """List all employees. Only authenticated users can access."""
    employees = crud.get_employees(db, skip=skip, limit=limit)
    return employees

# 3. GET SINGLE ROUTE (Read Employee by ID) / ផ្លូវសម្រាប់អានបុគ្គលិកតាម ID
@router.get("/search", response_model=list[schemas.EmployeeResponse])
def search_employees(
    q: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Search employees by first name, last name, email, or position."""
    return db.query(Employee).filter(
        or_(
            Employee.first_name.ilike(f"%{q}%"),
            Employee.last_name.ilike(f"%{q}%"),
            Employee.email.ilike(f"%{q}%"),
            Employee.position.ilike(f"%{q}%"),
        )
    ).all()


@router.get("/{employee_id}", response_model=schemas.EmployeeResponse)
def read_employee(
    employee_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Retrieve a single employee by ID. Returns 404 if not found."""
    # ខ្មែរ: ទាញបុគ្គលិកតាម UUID ។ 404 ប្រសិនបើមិនរក
    db_employee = crud.get_employee_by_id(db, employee_id=employee_id)
    if not db_employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    return db_employee

# 4. DELETE ROUTE (Delete Employee) / ផ្លូវសម្រាប់លុបបុគ្គលិក
@router.delete("/{employee_id}")
def delete_employee(
    employee_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete an employee by ID. Returns 404 if not found."""
    deleted_employee = crud.delete_employee(db=db, employee_id=employee_id)
    if not deleted_employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    return {"message": "Employee deleted successfully"}


# 5. PATCH ROUTE (Update Employee) / ផ្លូវសម្រាប់កែប្រែបុគ្គលិក
@router.patch("/{employee_id}", response_model=schemas.EmployeeResponse)
def update_employee(
    employee_id: str,
    updates: EmployeeUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """ខ្មែរ: ADMIN អាចកែប្រែព័ត៌មានបុគ្គលិក"""
    role = current_user.get("role")
    if role != "ADMIN":
        raise HTTPException(status_code=403, detail="Only ADMIN can update employees")
    updated = crud.update_employee(db=db, employee_id=employee_id,
                                   updates=updates.model_dump(exclude_none=True))
    if not updated:
        raise HTTPException(status_code=404, detail="Employee not found")
    return updated
