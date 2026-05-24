from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from database import get_db
from models import User
from security import hash_password, verify_password, create_access_token
from deps import get_current_user

router = APIRouter()


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    shop_name: str = "ຮ້ານຂອງຂ້ອຍ"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    shop_name: str

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


@router.post("/register", response_model=TokenResponse)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if len(body.password) < 6:
        raise HTTPException(status_code=400, detail="ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ")
    existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email ນີ້ຖືກໃຊ້ງານແລ້ວ")
    user = User(
        email=body.email,
        hashed_password=hash_password(body.password),
        shop_name=body.shop_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token({"sub": user.id})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email).first()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Email ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ")
    token = create_access_token({"sub": user.id})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))


@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me/shop-name")
def update_shop_name(body: dict, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    name = body.get("shop_name", "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="ກະລຸນາໃສ່ຊື່ຮ້ານ")
    current_user.shop_name = name
    db.commit()
    return {"shop_name": current_user.shop_name}
