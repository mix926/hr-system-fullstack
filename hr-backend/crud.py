from sqlalchemy.orm import Session
import models, schemas
from passlib.context import CryptContext

# Setup password hashing / រៀបចំប្រព័ន្ធបំប្លែងលេខសម្ងាត់
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str):
    return pwd_context.hash(password)

def get_employee_by_email(db: Session, email: str):
    return db.query(models.Employee).filter(models.Employee.email == email).first()

def get_employees(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Employee).offset(skip).limit(limit).all()

def create_employee(db: Session, employee: schemas.EmployeeCreate):
    # 1. Hash the password / បំប្លែងលេខសម្ងាត់ជាកូដ
    hashed_pw = get_password_hash(employee.password)
    
    # 2. Convert employee data to dictionary and remove the raw password 
    # បំប្លែងទិន្នន័យទៅជា dictionary រួចលុបលេខសម្ងាត់ដើមចេញ
    db_employee_data = employee.dict()
    del db_employee_data["password"]
    
    # 3. Add the hashed password / បញ្ចូលលេខសម្ងាត់ដែលបានបំប្លែងរួច
    db_employee_data["hashed_password"] = hashed_pw
    
    # 4. Save to database / រក្សាទុកក្នុង Database
    new_employee = models.Employee(**db_employee_data)
    db.add(new_employee)
    db.commit()
    db.refresh(new_employee)
    return new_employee

def delete_employee(db: Session, employee_id: int):
    db_employee = db.query(models.Employee).filter(models.Employee.id == employee_id).first()
    if db_employee:
        db.delete(db_employee)
        db.commit()
    return db_employee
def verify_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password,hashed_password)