from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime, date


class OrderOut(BaseModel):
    id: int
    order_id: Optional[str] = None
    shop_id: int
    amount: int
    items: Optional[Any] = None
    shipping_address: Optional[str] = None
    status: str
    payment_method: Optional[str] = None
    tracking_number: Optional[str] = None
    payment_due_date: Optional[date] = None
    paid_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OrderStatusUpdate(BaseModel):
    status: str
    tracking_number: Optional[str] = None


class OrderCancelRequest(BaseModel):
    reason: str


class OrderListResponse(BaseModel):
    items: List[OrderOut]
    total: int
    page: int
    limit: int
    pages: int
