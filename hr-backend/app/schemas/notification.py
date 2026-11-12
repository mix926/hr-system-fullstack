"""
Notification & Communication schemas:
- Notification CRUD (create, list, mark read)
- Announcement CRUD
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from app.models.notification import NotificationType


# ─── Notification Schemas ──────────────────────────────────────

class NotificationCreate(BaseModel):
    user_id: str
    notification_type: NotificationType = NotificationType.GENERAL
    title: str = Field(..., min_length=1, max_length=200)
    message: str
    link: Optional[str] = None


class NotificationResponse(BaseModel):
    id: str
    user_id: str
    notification_type: NotificationType
    title: str
    message: str
    link: Optional[str] = None
    is_read: bool
    read_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Announcement Schemas ──────────────────────────────────────

class AnnouncementBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str
    target_role: Optional[str] = None
    target_department_id: Optional[str] = None
    is_pinned: bool = False
    publish_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None


class AnnouncementCreate(AnnouncementBase):
    pass


class AnnouncementUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = None
    target_role: Optional[str] = None
    target_department_id: Optional[str] = None
    is_pinned: Optional[bool] = None
    is_active: Optional[bool] = None
    expiry_date: Optional[datetime] = None


class AnnouncementResponse(AnnouncementBase):
    id: str
    is_active: bool
    created_by: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
