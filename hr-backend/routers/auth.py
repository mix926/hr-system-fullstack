from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
import crud, models
from database import SessionLocal
import jwt
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordBearer

router = APIRouter(tags=["Authentication"])


# Secret key for JWT (In a real app, hide this in a .env file!)
# កូដសម្ងាត់សម្រាប់បង្កើត Token (ក្នុងកម្មវិធីពិត ត្រូវលាក់វាក្នុងឯកសារ .env!)
SECRET_KEY = "my_super_secret_hr_key"
ALGORITHM = "HS256"
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Data we expect the user to send from the Flutter Login Screen
# ទិន្នន័យដែលយើងរំពឹងថាអ្នកប្រើប្រាស់នឹងបញ្ជូនមកពីផ្ទាំង Login របស់ Flutter
class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(request: LoginRequest, db: Session = Depends(get_db)):
    # 1. Find the user by email / ស្វែងរកអ្នកប្រើប្រាស់តាមអ៊ីមែល
    user = crud.get_employee_by_email(db, email=request.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email")
    
    # 2. Verify the password / ផ្ទៀងផ្ទាត់លេខសម្ងាត់
    if not crud.verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid password")
        
    # 3. Generate JWT Token / បង្កើត Token
    expire = datetime.utcnow() + timedelta(hours=24) # Token valid for 24 hours / Token មានសុពលភាព ២៤ម៉ោង
    to_encode = {"sub": user.email, "role": user.role, "exp": expire}
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    # 4. Return the token and user details / បញ្ជូន Token និងព័ត៌មានអ្នកប្រើប្រាស់ត្រឡប់ទៅវិញ
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
        # Try to decode the token / ព្យាយាមបំប្លែង Token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        return payload # Returns the user's data (email, role)
    except jwt.PyJWTError:
        raise credentials_exception