from sqlalchemy import Column, Integer, String, Boolean
from database import Base

class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(50), index=True)
    last_name = Column(String(50), index=True)
    email = Column(String(100), unique=True, index=True)
    position = Column(String(50))
    hashed_password = Column(String(255))
    is_active = Column(Boolean, default=True)