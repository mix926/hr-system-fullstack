"""
Notification & Communication API:

- In-app notifications: list, mark read, mark all read, delete
- Announcements: CRUD with targeting by role/department
- Notification creation endpoint (for internal system use)
"""
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import Employee
from app.models.notification import (
    Notification,
    Announcement,
    NotificationType,
)
from app.schemas.notification import (
    NotificationCreate,
    NotificationResponse,
    AnnouncementCreate,
    AnnouncementUpdate,
    AnnouncementResponse,
)
from app.api.auth import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications & Communication"])

# ── Helpers ────────────────────────────────────────────────────

def _role(user) -> str:
    return user.role.value if hasattr(user.role, "value") else user.role


def _require_admin_or_manager(user):
    role = _role(user)
    if role not in ("ADMIN", "MANAGER"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN or MANAGER can perform this action",
        )


def _require_admin(user):
    if _role(user) != "ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only ADMIN can perform this action",
        )


# ─── In-App Notifications ──────────────────────────────────────

@router.get("/", response_model=List[NotificationResponse])
def get_my_notifications(
    unread_only: bool = False,
    limit: int = 50,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get notifications for the current user."""
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    if unread_only:
        query = query.filter(Notification.is_read == False)
    return query.order_by(Notification.created_at.desc()).limit(limit).all()


@router.get("/unread-count")
def get_unread_count(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get count of unread notifications for the current user."""
    count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False,
    ).count()
    return {"unread_count": count}


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a single notification as read."""
    notif = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id,
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    notif.read_at = datetime.utcnow()
    db.commit()
    db.refresh(notif)
    return notif


@router.post("/mark-all-read")
def mark_all_read(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark all notifications as read for the current user."""
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False,
    ).update({"is_read": True, "read_at": datetime.utcnow()})
    db.commit()
    return {"message": "All notifications marked as read"}


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a notification."""
    notif = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id,
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    db.delete(notif)
    db.commit()
    return {"message": "Notification deleted"}


# ─── Announcements ─────────────────────────────────────────────

@router.get("/announcements", response_model=List[AnnouncementResponse])
def get_announcements(
    active_only: bool = True,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List announcements visible to the current user.
    
    Filters by target_role (matching user's role) and target_department.
    """
    role = _role(current_user)
    query = db.query(Announcement)
    
    if active_only:
        query = query.filter(Announcement.is_active == True)
        # Filter by publish/expiry dates
        now = datetime.utcnow()
        query = query.filter(
            (Announcement.publish_date.is_(None)) | (Announcement.publish_date <= now)
        )
        # Not expired
        query = query.filter(
            (Announcement.expiry_date.is_(None)) | (Announcement.expiry_date >= now)
        )

    announcements = query.order_by(Announcement.is_pinned.desc(), Announcement.created_at.desc()).all()

    # Filter by target role and department
    result = []
    for ann in announcements:
        # Role targeting — show if target_role is null (all) or matches user's role
        if ann.target_role and ann.target_role != role:
            continue
        # Department targeting — show if target_department_id is null or matches user's department
        if ann.target_department_id and ann.target_department_id != current_user.department_id:
            continue
        result.append(ann)

    return result


@router.post("/announcements", response_model=AnnouncementResponse, status_code=status.HTTP_201_CREATED)
def create_announcement(
    body: AnnouncementCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new announcement. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    announcement = Announcement(
        **body.model_dump(),
        created_by=current_user.id,
        is_active=True,
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)

    # Create in-app notifications for targeted users
    users_query = db.query(Employee).filter(Employee.is_active == True)
    if body.target_role:
        from app.models.models import RoleEnum
        try:
            users_query = users_query.filter(Employee.role == RoleEnum(body.target_role))
        except ValueError:
            pass
    if body.target_department_id:
        users_query = users_query.filter(Employee.department_id == body.target_department_id)

    for user in users_query.all():
        notif = Notification(
            user_id=user.id,
            notification_type=NotificationType.ANNOUNCEMENT,
            title=body.title,
            message=body.content[:200] if body.content else "",
            link="/announcements",
        )
        db.add(notif)

    db.commit()
    return announcement


@router.patch("/announcements/{announcement_id}", response_model=AnnouncementResponse)
def update_announcement(
    announcement_id: str,
    body: AnnouncementUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update an announcement. ADMIN/MANAGER only."""
    _require_admin_or_manager(current_user)
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(announcement, key, value)
    db.commit()
    db.refresh(announcement)
    return announcement


@router.delete("/announcements/{announcement_id}")
def delete_announcement(
    announcement_id: str,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete an announcement. ADMIN only."""
    _require_admin(current_user)
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    db.delete(announcement)
    db.commit()
    return {"message": "Announcement deleted"}
