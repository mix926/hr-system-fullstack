from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import crud, schemas
from database import SessionLocal
from routers.auth import get_current_user
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

@router.post("/", response_model=schemas.EmployeeResponse)
def create_new_employee(
    employee: schemas.EmployeeCreate, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user) # <-- SECURITY LOCK / សោសុវត្ថិភាព
):
    db_employee = crud.get_employee_by_email(db, email=employee.email)
    if db_employee:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_employee(db=db, employee=employee)

@router.post("/", response_model=schemas.EmployeeResponse)
def create_new_employee(
    employee: schemas.EmployeeCreate, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user) # <-- SECURITY LOCK / សោសុវត្ថិភាព
):
    db_employee = crud.get_employee_by_email(db, email=employee.email)
    if db_employee:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_employee(db=db, employee=employee)
@router.delete("/{employee_id}")
def delete_employee(
    employee_id: int, 
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user) # <-- SECURITY LOCK / សោសុវត្ថិភាព
):
    deleted_employee = crud.delete_employee(db=db, employee_id=employee_id)
    if not deleted_employee:
        raise HTTPException(status_code=404, detail="Employee not found")
    return {"message": "Employee deleted successfully"}