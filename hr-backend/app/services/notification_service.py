"""
Notification service: handles sending notifications via multiple channels.

This module provides pluggable email/SMS hooks. In production, these would
connect to actual providers (SendGrid, Twilio, etc.). For now, they log
to stdout and can be easily replaced.
"""
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
from app.models.notification import Notification, NotificationType


# ── Email Hook ─────────────────────────────────────────────────

def send_email(
    to_email: str,
    subject: str,
    body: str,
    is_html: bool = False,
) -> bool:
    """Send an email notification.
    
    In production, configure SMTP settings in .env:
    SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, FROM_EMAIL
    
    For now, logs to stdout. Replace with actual SMTP or provider API.
    """
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")
    from_email = os.getenv("FROM_EMAIL", "noreply@company.com")

    if not smtp_host:
        # Dev mode — just log
        print(f"[EMAIL] To: {to_email} | Subject: {subject} | Body: {body[:100]}...")
        return True

    try:
        msg = MIMEMultipart()
        msg["From"] = from_email
        msg["To"] = to_email
        msg["Subject"] = subject
        if is_html:
            msg.attach(MIMEText(body, "html"))
        else:
            msg.attach(MIMEText(body, "plain"))

        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(from_email, to_email, msg.as_string())
        return True
    except Exception as e:
        print(f"[EMAIL ERROR] Failed to send to {to_email}: {e}")
        return False


# ── SMS Hook ────────────────────────────────────────────────────

def send_sms(
    to_phone: str,
    message: str,
) -> bool:
    """Send an SMS notification.
    
    In production, integrate with Twilio, AWS SNS, or similar.
    For now, logs to stdout.
    """
    twilio_sid = os.getenv("TWILIO_SID")
    
    if not twilio_sid:
        # Dev mode — just log
        print(f"[SMS] To: {to_phone} | Message: {message[:100]}...")
        return True

    # Production: use Twilio SDK
    # from twilio.rest import Client
    # client = Client(twilio_sid, os.getenv("TWILIO_TOKEN"))
    # client.messages.create(to=to_phone, from_=os.getenv("TWILIO_FROM"), body=message)
    print(f"[SMS] To: {to_phone} | Message: {message[:100]}...")
    return True


# ── Notification Dispatcher ────────────────────────────────────

def dispatch_notification(
    db,
    user,
    notification_type: NotificationType,
    title: str,
    message: str,
    link: Optional[str] = None,
    send_email_flag: bool = True,
    send_sms_flag: bool = False,
) -> Notification:
    """Create an in-app notification and optionally send email/SMS.
    
    Args:
        db: Database session
        user: Employee object
        notification_type: Type of notification
        title: Short title
        message: Full message body
        link: Optional deep link for the app
        send_email_flag: Whether to send email (default True)
        send_sms_flag: Whether to send SMS (default False)
    
    Returns:
        The created Notification object
    """
    # Create in-app notification
    notification = Notification(
        user_id=user.id,
        notification_type=notification_type,
        title=title,
        message=message,
        link=link,
        is_read=False,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)

    # Send email if enabled and user has email
    if send_email_flag and user.email:
        send_email(
            to_email=user.email,
            subject=title,
            body=message,
        )

    # Send SMS if enabled and user has phone
    if send_sms_flag and user.phone:
        send_sms(
            to_phone=user.phone,
            message=f"{title}: {message}",
        )

    return notification


def notify_leave_request(db, employee, approver, leave):
    """Helper: notify approver about a new leave request."""
    dispatch_notification(
        db, approver,
        NotificationType.LEAVE_REQUEST,
        f"New Leave Request from {employee.first_name} {employee.last_name}",
        f"{employee.first_name} {employee.last_name} has requested leave from {leave.start_date} to {leave.end_date}. Reason: {leave.reason or 'N/A'}",
        link=f"/leaves/{leave.id}",
    )


def notify_leave_status_change(db, employee, leave, status: str):
    """Helper: notify employee about leave approval/rejection."""
    notif_type = NotificationType.LEAVE_APPROVED if status == "APPROVED" else NotificationType.LEAVE_REJECTED
    dispatch_notification(
        db, employee,
        notif_type,
        f"Leave Request {status}",
        f"Your leave request from {leave.start_date} to {leave.end_date} has been {status.lower()}.",
        link=f"/leaves/{leave.id}",
    )
