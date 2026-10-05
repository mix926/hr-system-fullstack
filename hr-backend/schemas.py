from pydantic import BaseModel

# Base data we expect for an employee
class EmployeeBase(BaseModel):
    first_name: str
    last_name: str
    email: str
    position: str
    role: str = "Employee"

# Data required to create an employee
class EmployeeCreate(EmployeeBase):
    pass

# Data returned from the database (includes ID and active status)
class EmployeeResponse(EmployeeBase):
    id: int
    is_active: bool

    class Config:
        from_attributes = True