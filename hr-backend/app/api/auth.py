from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.repositories import crud
from app.models import models
from app.core.database import SessionLocal
import jwt
# NEW: Imported timezone to fix the instant-expiration bug / នាំចូល timezone 
from datetime import datetime, timedelta, timezone 
from fastapi.security import OAuth2PasswordBearer

router = APIRouter(tags=["Authentication"])

# NEW: Made the key 32+ characters long to remove the warning / បង្កើនប្រវែងកូដសម្ងាត់
SECRET_KEY = "my_super_secret_hr_key_1234567890" 
ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = crud.get_employee_by_email(db, email=request.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email")
    
    if not crud.verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid password")
        
    # NEW: Use timezone-aware UTC time / ប្រើប្រាស់ពេលវេលា UTC ច្បាស់លាស់
    expire = datetime.now(timezone.utc) + timedelta(hours=24) 
    to_encode = {"sub": user.email, "role": user.role, "exp": expire}
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "role": user.role,
            "first_name": user.first_name,
            "last_name": user.last_name
        }
    }

def get_current_user(token: str = Depends(oauth2_scheme)):
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
        return payload 
    except jwt.ExpiredSignatureError:
        print("JWT ERROR: Token has expired!") # Prints to your terminal / បង្ហាញក្នុង Terminal
        raise credentials_exception
    except jwt.PyJWTError as e:
        print(f"JWT ERROR: {e}") # Prints exact error to your terminal / បង្ហាញកំហុសច្បាស់លាស់
        raise credentials_exception