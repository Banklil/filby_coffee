from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from ..database import get_db
from ..models.shop_owner import ShopOwner
from ..models.shop import Shop
from ..models.product import Product
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
    shop_name: str = "ຮ້ານຂອງຂ້ອຍ"
    phone: Optional[str] = None
    address: Optional[str] = None

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
    db.flush()

    # Auto-create Shop record for admin dashboard visibility
    count = db.query(Shop).count()
    shop_id = f"FC{str(count + 1).zfill(4)}"
    shop = Shop(
        shop_id=shop_id,
        name=body.shop_name,
        owner_name=body.shop_name,
        phone="—",
        email=body.email,
        province="ວຽງຈັນ",
        status="pending",
        tier="bronze",
        credit_limit=0,
        credit_used=0,
    )
    db.add(shop)
    db.commit()
    db.refresh(owner)
    return TokenResponse(
        access_token=create_access_token({"sub": str(owner.id)}),
        refresh_token=create_refresh_token({"sub": str(owner.id)}),
        user=OwnerOut.model_validate(owner),
    )


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    try:
        owner = db.query(ShopOwner).filter(ShopOwner.email == body.email, ShopOwner.active == True).first()
        if not owner or not verify_password(body.password, owner.password_hash):
            raise HTTPException(status_code=401, detail="Email ຫຼື ລະຫັດຜ່ານບໍ່ຖືກ")
        return TokenResponse(
            access_token=create_access_token({"sub": str(owner.id)}),
            refresh_token=create_refresh_token({"sub": str(owner.id)}),
            user=OwnerOut.model_validate(owner),
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"[LOGIN ERROR] {type(e).__name__}: {e}")
        raise HTTPException(status_code=500, detail=f"Server error: {type(e).__name__}")


@router.get("/me", response_model=OwnerOut)
def me(owner: ShopOwner = Depends(_get_owner)):
    return owner


class ProfileUpdate(BaseModel):
    shop_name: Optional[str] = None
    phone:     Optional[str] = None
    address:   Optional[str] = None


@router.patch("/profile", response_model=OwnerOut)
def update_profile(body: ProfileUpdate, owner: ShopOwner = Depends(_get_owner), db: Session = Depends(get_db)):
    if body.shop_name is not None:
        owner.shop_name = body.shop_name
    if body.phone is not None:
        owner.phone = body.phone
    if body.address is not None:
        owner.address = body.address
    # Sync to admin shops table too
    try:
        shop = db.query(Shop).filter(Shop.email == owner.email).first()
        if shop:
            if body.shop_name:
                shop.name = body.shop_name
            if body.phone:
                shop.phone = body.phone
    except Exception:
        pass
    db.commit()
    db.refresh(owner)
    return owner


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    new_password: str
    shop_name: str = "ຮ້ານຂອງຂ້ອຍ"


@router.post("/reset-password")
def reset_password(body: ResetPasswordRequest, db: Session = Depends(get_db)):
    """Upsert shop owner with a fresh bcrypt hash — dev/support tool."""
    try:
        if len(body.new_password) < 6:
            raise HTTPException(status_code=400, detail="ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ")
        owner = db.query(ShopOwner).filter(ShopOwner.email == body.email).first()
        if owner:
            owner.password_hash = get_password_hash(body.new_password)
            owner.active = True
            if not owner.shop_name:
                owner.shop_name = body.shop_name
        else:
            owner = ShopOwner(
                email=body.email,
                password_hash=get_password_hash(body.new_password),
                shop_name=body.shop_name,
                active=True,
            )
            db.add(owner)
        db.commit()
        db.refresh(owner)
        return {"message": "ຕັ້ງລະຫັດຜ່ານໃໝ່ສຳເລັດ", "id": owner.id, "email": owner.email}
    except HTTPException:
        raise
    except Exception as e:
        print(f"[RESET ERROR] {type(e).__name__}: {e}")
        raise HTTPException(status_code=500, detail=f"{type(e).__name__}: {e}")


# ---- Products (shared catalog managed by admin web) ----

class ProductOut(BaseModel):
    id: int
    name: str
    category: str
    price: int
    unit: Optional[str] = None
    stock_qty: float
    image_url: Optional[str] = None

    class Config:
        from_attributes = True


@router.get("/products", response_model=List[ProductOut])
def get_products(
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    q = db.query(Product).filter(Product.active == True)
    if category:
        q = q.filter(Product.category == category)
    return q.order_by(Product.category, Product.name).all()
