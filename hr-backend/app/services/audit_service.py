"""
Audit logging helper.

Usage in any API endpoint:
    from app.services.audit_service import log_action, AuditAction

    log_action(
        db=db,
        actor=current_user,
        action=AuditAction.UPDATE,
        entity_type="employee",
        entity_id=employee_id,
        description="Updated employee status to ACTIVE",
        old_values={"status": "ONBOARDING"},
        new_values={"status": "ACTIVE"},
        request=request,  # optional FastAPI Request for IP/user-agent
    )
"""
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session
from app.models.audit import AuditLog, AuditAction


def log_action(
    db: Session,
    actor,
    action: AuditAction,
    entity_type: str,
    entity_id: Optional[str] = None,
    description: Optional[str] = None,
    old_values: Optional[Dict[str, Any]] = None,
    new_values: Optional[Dict[str, Any]] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    request=None,
) -> AuditLog:
    """Create an audit log entry.

    Args:
        db: Database session
        actor: Employee object (or None for system actions)
        action: AuditAction enum value
        entity_type: Type of entity being acted on (e.g., "employee", "leave")
        entity_id: ID of the entity
        description: Human-readable summary
        old_values: State before the change
        new_values: State after the change
        ip_address: Override IP address (if not using request)
        user_agent: Override user agent string
        request: FastAPI Request object for auto IP/UA extraction

    Returns:
        The created AuditLog instance
    """
    # Extract IP and UA from request if provided
    if request is not None:
        ip_address = ip_address or _get_client_ip(request)
        user_agent = user_agent or request.headers.get("user-agent")

    log = AuditLog(
        actor_id=actor.id if actor else None,
        actor_email=actor.email if actor else None,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id else None,
        description=description,
        old_values=old_values,
        new_values=new_values,
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


def _get_client_ip(request) -> Optional[str]:
    """Extract the real client IP, respecting X-Forwarded-For header."""
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else None
