from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.repositories import crud
from app.schemas import schemas
from app.core.database import SessionLocal
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

# 1. POST ROUTE (Create Employee) / ផ្លូវសម្រាប់បង្កើតបុគ្គលិក
@router.post("/", response_model=schemas.EmployeeResponse)
def create_new_employee(
    employee: schemas.EmployeeCreate, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    db_employee = crud.get_employee_by_email(db, email=employee.email)
    if db_employee:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_employee(db=db, employee=employee)

# 2. GET ROUTE (Read Employees) / ផ្លូវសម្រាប់អានទិន្នន័យបុគ្គលិក (THIS WAS MISSING!)
@router.get("/", response_model=list[schemas.EmployeeResponse])
def read_employees(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    employees = crud.get_employees(db, skip=skip, limit=limit)
    return employees

# 3. DELETE ROUTE (Delete Employee) / ផ្លូវសម្រាប់លុបបុគ្គលិក
@router.delete("/{employee_id}")
def delete_employee(
    employee_id: int, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    deleted_employee = crud.delete_employee(db=db, employee_id=employee_id)
    if not deleted_employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    return {"message": "Employee deleted successfully"}