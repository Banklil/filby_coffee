from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ProductOut(BaseModel):
    id: int
    name: str
    origin: Optional[str] = None
    category: str
    price: int
    unit: Optional[str] = None
    stock_qty: float
    image_url: Optional[str] = None
    active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ProductCreate(BaseModel):
    name: str
    category: str
    price: int
    origin: Optional[str] = None
    unit: Optional[str] = None
    stock_qty: float = 0


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    price: Optional[int] = None
    origin: Optional[str] = None
    unit: Optional[str] = None
    image_url: Optional[str] = None
    active: Optional[bool] = None


class StockUpdate(BaseModel):
    delta: float
