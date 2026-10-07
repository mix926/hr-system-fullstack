# Location: app/schemas/schemas.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

# ខ្មែរ: ទាញយក RoleEnum ពី models មកប្រើ ដើម្បីកុំឱ្យខុសប្រភេទប្លុកទិន្នន័យ
from app.models.models import RoleEnum

# ខ្មែរ: Base Data DTO (ទិន្នន័យរួមដែលត្រូវប្រើច្រើនដង)
class EmployeeBase(BaseModel):
    # ខ្មែរ: បង្ខំឱ្យឈ្មោះមានយ៉ាងតិច ២ ដល់ ៥០ តួអក្សរ
    first_name: str = Field(..., min_length=2, max_length=50)
    last_name: str = Field(..., min_length=2, max_length=50)
    
    # ខ្មែរ: EmailStr នឹងឆែកមើលថាវាមាន @ និង .com ត្រឹមត្រូវឬអត់ដោយស្វ័យប្រវត្តិ
    email: EmailStr 
    
    position: Optional[str] = None
    department_id: Optional[str] = None
    
    # ខ្មែរ: ប្រើប្រាស់ RoleEnum ជំនួស String ធម្មតា
    role: RoleEnum = RoleEnum.STAFF

# ខ្មែរ: DTO សម្រាប់ទទួលទិន្នន័យពី Frontend ពេលបង្កើតបុគ្គលិកថ្មី
class EmployeeCreate(EmployeeBase):
    # ខ្មែរ: បង្ខំឱ្យលេខសម្ងាត់ត្រូវតែមានយ៉ាងហោចណាស់ ៨ តួអក្សរ
    password: str = Field(..., min_length=8)

# ខ្មែរ: DTO សម្រាប់ឆ្លើយតប (Response) បញ្ជូនទិន្នន័យត្រលប់ទៅ Frontend វិញ
class EmployeeResponse(EmployeeBase):
    # ខ្មែរ: ត្រូវតែប្តូរពី int ទៅជា str វិញព្រោះ Database យើងប្រើ UUID
    id: str
    is_active: bool
    
    # ខ្មែរ: បន្ថែមពេលវេលាប្រវត្តិទិន្នន័យ (Audit Trails)
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        # ខ្មែរ: អនុញ្ញាតឱ្យ Pydantic អាចទាញយកទិន្នន័យពីមុខងាររបស់ SQLAlchemy ORM បាន
        from_attributes = True