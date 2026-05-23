from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: "AdminOut"


class RefreshRequest(BaseModel):
    refresh_token: str


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


class PasswordResetRequest(BaseModel):
    email: EmailStr


class PasswordUpdateRequest(BaseModel):
    token: str
    new_password: str


TokenResponse.model_rebuild()
