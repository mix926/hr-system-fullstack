# Location: app/repositories/crud.py
from sqlalchemy.orm import Session

# ខ្មែរ: ទាញយកពីទីតាំងថ្មីនៅក្នុង Clean Architecture
from app.models.models import Employee
# ខ្មែរ: បើសិនអ្នកមិនទាន់មាន schemas.py ត្រឹមត្រូវទេ យើងនឹងរៀនវានៅមេរៀនក្រោយ
from app.schemas.schemas import EmployeeCreate 
from app.core.security import get_password_hash

# ខ្មែរ: ទាញយកបុគ្គលិកតាមរយៈ Email
def get_employee_by_email(db: Session, email: str):
    return db.query(Employee).filter(Employee.email == email).first()

# ខ្មែរ: ទាញយកបុគ្គលិកទាំងអស់ជាមួយ Pagination (skip, limit)
def get_employees(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Employee).offset(skip).limit(limit).all()

# ខ្មែរ: បង្កើតបុគ្គលិកថ្មី
def create_employee(db: Session, employee: EmployeeCreate):
    # ខ្មែរ: ហៅអនុគមន៍ Hash ពីឯកសារ security.py វិញ
    hashed_pw = get_password_hash(employee.password)
    
    # ខ្មែរ: Pydantic V2 ប្រើ model_dump() ជំនួស dict() ដែលហួសសម័យ
    # ខ្មែរ: បើយកទៅរត់ហើយ Error សូមដូរទៅជា employee.dict() វិញ
    db_employee_data = employee.model_dump() 
    
    # ខ្មែរ: លុបលេខសម្ងាត់ដើមចេញ ហើយដាក់លេខសម្ងាត់ដែល Hash រួចជំនួសវិញ
    del db_employee_data["password"]
    db_employee_data["hashed_password"] = hashed_pw
    
    new_employee = Employee(**db_employee_data)
    db.add(new_employee)
    db.commit()
    db.refresh(new_employee)
    return new_employee

# ខ្មែរ: កែប្រែប្រភេទ employee_id ទៅជា str វិញ ព្រោះយើងកំពុងប្រើ UUID
def delete_employee(db: Session, employee_id: str):
    db_employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if db_employee:
        db.delete(db_employee)
        db.commit()
    return db_employee