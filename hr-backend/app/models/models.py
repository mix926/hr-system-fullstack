import uuid
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

# ខ្មែរ: កែប្រែ Import ទៅទីតាំងថ្មីនៅក្នុង Clean Architecture
from app.core.database import Base

# ខ្មែរ: កំណត់ប្រភេទ Role ឱ្យបានច្បាស់លាស់ (ការពារការសរសេរខុសអក្ខរាវិរុទ្ធ)
class RoleEnum(str, enum.Enum):
    ADMIN = "ADMIN"
    MANAGER = "MANAGER"
    STAFF = "STAFF"

# ខ្មែរ: បង្កើតតារាងនាយកដ្ឋាន (Department)
class Department(Base):
    __tablename__ = "departments"

    # ខ្មែរ: ប្រើ UUID ជំនួស Auto-increment
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)
    
    # ខ្មែរ: កត់ត្រាពេលវេលាបង្កើតទិន្នន័យដោយស្វ័យប្រវត្តិ
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # ខ្មែរ: ទំនាក់ទំនង 1 នាយកដ្ឋាន មានបុគ្គលិកច្រើន
    employees = relationship("Employee", back_populates="department")

# ខ្មែរ: តារាងបុគ្គលិកដែលតម្លើងរួច (Upgraded Employee Model)
class Employee(Base):
    __tablename__ = "employees"

    # ខ្មែរ: ប្រើ UUID ដើម្បីការពារ IDOR Attack
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # ខ្មែរ: ភ្ជាប់ទៅកាន់តារាងនាយកដ្ឋាន (Foreign Key)
    department_id = Column(String(36), ForeignKey("departments.id"), nullable=True)

    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    position = Column(String(50))
    hashed_password = Column(String(255), nullable=False)
    
    # ខ្មែរ: ប្រើ Enum ជំនួស String ធម្មតា ដើម្បីបិទមិនឱ្យបញ្ជូលតួនាទីផ្តេសផ្តាស
    role = Column(Enum(RoleEnum), default=RoleEnum.STAFF)
    is_active = Column(Boolean, default=True)
    
    # ខ្មែរ: Audit Logs (ដឹងថាបង្កើតពេលណា និងកែប្រែចុងក្រោយពេលណា)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # ខ្មែរ: ភ្ជាប់ទំនាក់ទំនងត្រលប់ទៅកាន់នាយកដ្ឋានវិញ (ORM Relationship)
    department = relationship("Department", back_populates="employees")