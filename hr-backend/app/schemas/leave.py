from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class LeaveBase(BaseModel):
    leave_type: str
    start_date: datetime
    end_date: datetime
    reason: Optional[str] = None


class LeaveCreate(LeaveBase):
    pass


class LeaveResponse(LeaveBase):
    id: str
    employee_id: str
    status: str
    created_at: datetime

    class Config:
        # ខ្មែរ: Pydantic v2 ប្រើ from_attributes ជំនួស orm_mode
        from_attributes = True
