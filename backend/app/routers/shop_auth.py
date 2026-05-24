from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from ..database import get_db
from ..models.shop_owner import ShopOwner
from ..core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/api/shop", tags=["shop-owner"])

bearer = HTTPBearer()


def _get_owner(credentials: HTTPAuthorizationCredentials = Depends(bearer), db: Session = Depends(get_db)) -> ShopOwner:
    payload = decode_token(credentials.credentials)
    if not payload or payload.get("type") == "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token ໝົດອາຍຸ")
    owner = db.query(ShopOwner).filter(ShopOwner.id == int(payload["sub"]), ShopOwner.active == True).first()
    if not owner:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="ບໍ່ພົບບັນຊີ")
    return owner


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    shop_name: str = "ຮ້ານຂອງຂ້ອຍ"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class OwnerOut(BaseModel):
    id: int
    email: str
    shop_name: str

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: OwnerOut


@router.post("/register", response_model=TokenResponse)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if len(body.password) < 6:
        raise HTTPException(status_code=400, detail="ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ")
    if db.query(ShopOwner).filter(ShopOwner.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email ນີ້ຖືກໃຊ້ແລ້ວ")
    owner = ShopOwner(email=body.email, password_hash=get_password_hash(body.password), shop_name=body.shop_name)
    db.add(owner)
    db.commit()
    db.refresh(owner)
    return TokenResponse(
        access_token=create_access_token({"sub": str(owner.id)}),
        refresh_token=create_refresh_token({"sub": str(owner.id)}),
        user=OwnerOut.model_validate(owner),
    )


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    owner = db.query(ShopOwner).filter(ShopOwner.email == body.email, ShopOwner.active == True).first()
    if not owner or not verify_password(body.password, owner.password_hash):
        raise HTTPException(status_code=401, detail="Email ຫຼື ລະຫັດຜ່ານບໍ່ຖືກ")
    return TokenResponse(
        access_token=create_access_token({"sub": str(owner.id)}),
        refresh_token=create_refresh_token({"sub": str(owner.id)}),
        user=OwnerOut.model_validate(owner),
    )


@router.get("/me", response_model=OwnerOut)
def me(owner: ShopOwner = Depends(_get_owner)):
    return owner
