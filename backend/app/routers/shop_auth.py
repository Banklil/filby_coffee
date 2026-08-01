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
    bean_balance_kg: float = 0

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


# ---- Bean stock (remaining coffee, in kilograms) ----

class StockOut(BaseModel):
    bean_balance_kg: float


@router.get("/stock", response_model=StockOut)
def get_stock(owner: ShopOwner = Depends(_get_owner)):
    return StockOut(bean_balance_kg=float(owner.bean_balance_kg or 0))


class PosSaleRequest(BaseModel):
    beans_kg: float = 0            # total coffee beans consumed by this sale, in kg
    total_price: float = 0        # total sale amount, in kip
    items: Optional[list] = None  # [{name, qty, price}]


class PosSaleResult(BaseModel):
    bean_balance_kg: float
    deducted_kg: float
    insufficient: bool = False


@router.post("/pos-sale", response_model=PosSaleResult)
def pos_sale(body: PosSaleRequest, owner: ShopOwner = Depends(_get_owner), db: Session = Depends(get_db)):
    """Record a POS sale and deduct beans from the shop's stock.
    Balance is floored at 0; `insufficient` flags when the sale exceeded stock."""
    from ..models.pos_sale import PosSale

    want = max(0.0, float(body.beans_kg or 0))
    current = float(owner.bean_balance_kg or 0)
    insufficient = want > current
    deducted = min(want, current)
    owner.bean_balance_kg = round(current - deducted, 4)

    # Persist the sale so income / best-seller reports have data.
    db.add(PosSale(
        owner_id=owner.id,
        amount=float(body.total_price or 0),
        beans_kg=want,
        items=body.items,
    ))
    db.commit()
    db.refresh(owner)
    return PosSaleResult(
        bean_balance_kg=float(owner.bean_balance_kg or 0),
        deducted_kg=deducted,
        insufficient=insufficient,
    )


@router.get("/summary")
def shop_summary(
    period: str = "month",  # "day" | "week" | "month"
    owner: ShopOwner = Depends(_get_owner),
    db: Session = Depends(get_db),
):
    """Income / expense / net-profit + weekly chart + best sellers for the shop.
    Income = POS sales; expense = bean purchases (bean orders)."""
    from datetime import date, timedelta
    from sqlalchemy import func as _f
    from ..models.pos_sale import PosSale

    today = date.today()
    if period == "day":
        start = today
    elif period == "week":
        start = today - timedelta(days=6)
    else:
        start = today.replace(day=1)

    income = db.query(_f.coalesce(_f.sum(PosSale.amount), 0)).filter(
        PosSale.owner_id == owner.id,
        _f.date(PosSale.created_at) >= start,
    ).scalar() or 0

    sales_count = db.query(_f.count(PosSale.id)).filter(
        PosSale.owner_id == owner.id,
        _f.date(PosSale.created_at) >= start,
    ).scalar() or 0

    expense = db.query(_f.coalesce(_f.sum(BeanOrder.total_price), 0)).filter(
        BeanOrder.owner_id == owner.id,
        _f.date(BeanOrder.created_at) >= start,
        BeanOrder.status != "cancelled",
    ).scalar() or 0

    # ── Weekly chart: income vs expense for the last 7 days ──────────────
    weekly = []
    labels = ["ຈ", "ອ", "ພ", "ພຫ", "ສຸ", "ສ", "ອາ"]
    for i in range(6, -1, -1):
        d = today - timedelta(days=i)
        inc = db.query(_f.coalesce(_f.sum(PosSale.amount), 0)).filter(
            PosSale.owner_id == owner.id, _f.date(PosSale.created_at) == d,
        ).scalar() or 0
        exp = db.query(_f.coalesce(_f.sum(BeanOrder.total_price), 0)).filter(
            BeanOrder.owner_id == owner.id, _f.date(BeanOrder.created_at) == d,
            BeanOrder.status != "cancelled",
        ).scalar() or 0
        weekly.append({"label": labels[d.weekday()], "income": float(inc), "expense": float(exp)})

    # ── Best sellers: aggregate item names across POS sales in period ────
    sales = db.query(PosSale).filter(
        PosSale.owner_id == owner.id,
        _f.date(PosSale.created_at) >= start,
    ).all()
    agg: dict = {}
    for s in sales:
        for it in (s.items or []):
            if not isinstance(it, dict):
                continue
            name = it.get("name") or "—"
            qty = float(it.get("qty") or 0)
            revenue = float(it.get("price") or 0) * qty
            row = agg.setdefault(name, {"name": name, "qty": 0.0, "revenue": 0.0})
            row["qty"] += qty
            row["revenue"] += revenue
    top_items = sorted(agg.values(), key=lambda r: r["revenue"], reverse=True)[:5]

    return {
        "period":          period,
        "income":          float(income),
        "expense":         float(expense),
        "net_profit":      float(income) - float(expense),
        "sales_count":     int(sales_count),
        "bean_balance_kg": float(owner.bean_balance_kg or 0),
        "weekly":          weekly,
        "top_items":       top_items,
    }


@router.get("/sales")
def shop_sales(
    period: str = "month",  # "day" | "week" | "month" | "all"
    owner: ShopOwner = Depends(_get_owner),
    db: Session = Depends(get_db),
):
    """Sales history for the shop: per-menu totals + recent transactions."""
    from datetime import date, timedelta
    from sqlalchemy import func as _f
    from ..models.pos_sale import PosSale

    today = date.today()
    if period == "day":
        start = today
    elif period == "week":
        start = today - timedelta(days=6)
    elif period == "all":
        start = None
    else:
        start = today.replace(day=1)

    q = db.query(PosSale).filter(PosSale.owner_id == owner.id)
    if start is not None:
        q = q.filter(_f.date(PosSale.created_at) >= start)
    sales = q.order_by(PosSale.created_at.desc()).all()

    # ── Per-menu aggregation across all sales in the period ──────────────
    by_item: dict = {}
    for s in sales:
        for it in (s.items or []):
            if not isinstance(it, dict):
                continue
            name = it.get("name") or "—"
            qty = float(it.get("qty") or 0)
            revenue = float(it.get("price") or 0) * qty
            row = by_item.setdefault(name, {"name": name, "qty": 0.0, "revenue": 0.0, "count": 0})
            row["qty"] += qty
            row["revenue"] += revenue
            row["count"] += 1
    by_item_list = sorted(by_item.values(), key=lambda r: r["revenue"], reverse=True)

    recent = [
        {
            "id":         s.id,
            "amount":     float(s.amount or 0),
            "beans_kg":   float(s.beans_kg or 0),
            "items":      s.items or [],
            "created_at": s.created_at.isoformat() if s.created_at else None,
        }
        for s in sales[:100]
    ]

    return {"period": period, "by_item": by_item_list, "recent": recent}
