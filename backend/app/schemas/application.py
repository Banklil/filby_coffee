from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime


class ApplicationOut(BaseModel):
    id: int
    ref_id: Optional[str] = None
    shop_data: Optional[Any] = None
    credit_requested: int
    purpose: Optional[str] = None
    status: str
    reviewed_by: Optional[int] = None
    reviewed_at: Optional[datetime] = None
    review_notes: Optional[str] = None
    approved_limit: Optional[int] = None
    shop_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class ApproveRequest(BaseModel):
    approved_limit: int
    notes: Optional[str] = None


class RejectRequest(BaseModel):
    reason: str


class RequestInfoRequest(BaseModel):
    message: str


class ApplicationListResponse(BaseModel):
    items: List[ApplicationOut]
    total: int
    page: int
    limit: int
    pages: int
