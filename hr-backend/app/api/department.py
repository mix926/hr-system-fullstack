from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.core.database import get_db
from app.models.models import Department
from app.api.auth import get_current_user

router = APIRouter(prefix="/departments", tags=["Departments"])


# ---- Schemas ----

class DepartmentCreate(BaseModel):
    name: str

class DepartmentResponse(BaseModel):
    id: str
    name: str
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ---- Endpoints ----

@router.get("/", response_model=List[DepartmentResponse])
def get_departments(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """List all departments. Only authenticated users can access."""
    return db.query(Department).all()


@router.post("/", response_model=DepartmentResponse, status_code=status.HTTP_201_CREATED)
def create_department(
    body: DepartmentCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Create a new department. Only ADMIN users can access."""
    role = current_user.get("role")
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can create departments"
        )
    existing = db.query(Department).filter(Department.name == body.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Department already exists")

    dept = Department(name=body.name)
    db.add(dept)
    db.commit()
    db.refresh(dept)
    return dept


@router.delete("/{department_id}", status_code=status.HTTP_200_OK)
def delete_department(
    department_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete a department by ID. Only ADMIN users can access."""
    role = current_user.get("role")
    if role != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can delete departments"
        )
    dept = db.query(Department).filter(Department.id == department_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    db.delete(dept)
    db.commit()
    return {"message": "Department deleted successfully"}
