from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any
from datetime import datetime


class ShopOut(BaseModel):
    id: int
    shop_id: Optional[str]
    name: str
    owner_name: str
    phone: str
    email: Optional[str]
    province: str
    district: Optional[str]
    village: Optional[str]
    address_detail: Optional[str]
    years_in_biz: Optional[str]
    revenue_range: Optional[str]
    shop_types: Optional[Any]
    staff_count: Optional[str]
    credit_limit: int
    credit_used: int
    tier: str
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ShopUpdate(BaseModel):
    name: Optional[str] = None
    owner_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    province: Optional[str] = None
    district: Optional[str] = None
    village: Optional[str] = None
    address_detail: Optional[str] = None
    tier: Optional[str] = None
    status: Optional[str] = None


class CreditLimitUpdate(BaseModel):
    new_limit: int
    reason: str


class ShopListResponse(BaseModel):
    items: List[ShopOut]
    total: int
    page: int
    limit: int
    pages: int
