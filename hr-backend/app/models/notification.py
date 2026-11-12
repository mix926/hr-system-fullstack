"""
Notification & Communication models:

- Notification: in-app alerts for individual users (leave approvals, payslips, etc.)
- Announcement: broadcast notices visible to all or role-targeted groups
"""
import enum
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, Enum, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class NotificationType(str, enum.Enum):
    """Categories of in-app notifications."""
    LEAVE_REQUEST = "LEAVE_REQUEST"
    LEAVE_APPROVED = "LEAVE_APPROVED"
    LEAVE_REJECTED = "LEAVE_REJECTED"
    PAYSLIP_GENERATED = "PAYSLIP_GENERATED"
    DOCUMENT_EXPIRY = "DOCUMENT_EXPIRY"
    PERFORMANCE_REVIEW = "PERFORMANCE_REVIEW"
    INTERVIEW_SCHEDULED = "INTERVIEW_SCHEDULED"
    OFFER_STATUS = "OFFER_STATUS"
    ANNOUNCEMENT = "ANNOUNCEMENT"
    GENERAL = "GENERAL"


class Notification(Base):
    """An in-app notification for a specific user."""
    __tablename__ = "notifications"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    user_id = Column(
        String(36), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True
    )

    notification_type = Column(Enum(NotificationType), default=NotificationType.GENERAL, nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    link = Column(String(500), nullable=True)           # Deep link to relevant page in app

    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("Employee", foreign_keys=[user_id], backref="notifications")


class Announcement(Base):
    """A broadcast announcement visible to all or targeted groups."""
    __tablename__ = "announcements"

    id = Column(String(36), primary_key=True, default=lambda: __import__('uuid').uuid4().__str__())
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)

    # Targeting — null means all employees
    target_role = Column(String(20), nullable=True)      # "ADMIN", "MANAGER", "STAFF", or null for all
    target_department_id = Column(
        String(36), ForeignKey("departments.id", ondelete="SET NULL"), nullable=True
    )

    # Priority
    is_pinned = Column(Boolean, default=False)           # Pinned to top
    is_active = Column(Boolean, default=True)

    # Scheduling
    publish_date = Column(DateTime(timezone=True), nullable=True)
    expiry_date = Column(DateTime(timezone=True), nullable=True)

    created_by = Column(String(36), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    creator = relationship("Employee", foreign_keys=[created_by])
    department = relationship("Department")
