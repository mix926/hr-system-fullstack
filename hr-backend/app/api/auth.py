from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.repositories import crud
from app.models import models
from app.models.models import RoleEnum
from app.schemas import schemas
from app.core.database import SessionLocal
from app.core.security import verify_password
import os
import jwt
from datetime import datetime, timedelta, timezone 
from fastapi.security import OAuth2PasswordBearer
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(tags=["Authentication"])

# Load JWT config from environment
SECRET_KEY = os.getenv("JWT_SECRET", "fallback-dev-secret-change-me-in-production-64chars")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_HOURS = int(os.getenv("JWT_EXPIRE_HOURS", "24"))

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/register", response_model=schemas.EmployeeResponse)
def register(employee: schemas.EmployeeCreate, db: Session = Depends(get_db)):
    """Public registration endpoint. No auth required.
    
    Security: Role is always forced to STAFF regardless of client input.
    """
    db_employee = crud.get_employee_by_email(db, email=employee.email)
    if db_employee:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Force role to STAFF — public registration is STAFF only
    employee.role = RoleEnum.STAFF
    return crud.create_employee(db=db, employee=employee)

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = crud.get_employee_by_email(db, email=request.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email")
    
    if not verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid password")
        
    # Use timezone-aware UTC time
    expire = datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRE_HOURS) 
    # Store the role value as a plain string so it survives JWT round-trip
    role_value = user.role.value if hasattr(user.role, "value") else user.role
    to_encode = {"sub": user.email, "role": role_value, "exp": expire}
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "role": role_value,
            "first_name": user.first_name,
            "last_name": user.last_name
        }
    }

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials or token expired",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        user = crud.get_employee_by_email(db, email=email)
        if user is None:
            raise credentials_exception
        return user
    except jwt.ExpiredSignatureError:
        print("JWT ERROR: Token has expired!")
        raise credentials_exception
    except jwt.PyJWTError as e:
        print(f"JWT ERROR: {e}")
        raise credentials_exception
