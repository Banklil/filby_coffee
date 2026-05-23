from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class AdminCreate(BaseModel):
    email: EmailStr
    name: str
    password: str
    role: str = "support"


class AdminUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None
    active: Optional[bool] = None
    password: Optional[str] = None


class AdminOut(BaseModel):
    id: int
    email: str
    name: str
    role: str
    active: bool
    last_login: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True
