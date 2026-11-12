"""
Admin & Security schemas:
- AuditLog (read-only)
- Company CRUD
- Branch CRUD
"""
from datetime import datetime
from typing import Optional, Any, Dict
from pydantic import BaseModel, Field
from app.models.audit import AuditAction


# ─── AuditLog Schemas (read-only) ─────────────────────────────

class AuditLogResponse(BaseModel):
    id: str
    actor_id: Optional[str] = None
    actor_email: Optional[str] = None
    action: AuditAction
    entity_type: str
    entity_id: Optional[str] = None
    description: Optional[str] = None
    old_values: Optional[Dict[str, Any]] = None
    new_values: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ─── Company Schemas ───────────────────────────────────────────

class CompanyBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    legal_name: Optional[str] = None
    registration_number: Optional[str] = None
    country: Optional[str] = None
    timezone: str = "UTC"
    currency: str = "USD"
    logo_path: Optional[str] = None


class CompanyCreate(CompanyBase):
    pass


class CompanyUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    legal_name: Optional[str] = None
    registration_number: Optional[str] = None
    country: Optional[str] = None
    timezone: Optional[str] = None
    currency: Optional[str] = None
    logo_path: Optional[str] = None
    is_active: Optional[bool] = None


class CompanyResponse(CompanyBase):
    id: str
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Branch Schemas ────────────────────────────────────────────

class BranchBase(BaseModel):
    company_id: str
    name: str = Field(..., min_length=1, max_length=200)
    code: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    manager_id: Optional[str] = None


class BranchCreate(BranchBase):
    pass


class BranchUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    code: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    manager_id: Optional[str] = None
    is_active: Optional[bool] = None


class BranchResponse(BranchBase):
    id: str
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
