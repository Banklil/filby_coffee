"""
/api/orders/beans — Bean order endpoints for merchant (ShopOwner) accounts.
Real-time: on POST, broadcasts new_bean_order to all connected admin sockets.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import date

from ..database import get_db
from ..models.bean_order import BeanOrder
from ..models.shop_owner import ShopOwner
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/orders/beans", tags=["bean-orders"])


# ── Schemas ─────────────────────────────────────────────────────────
class BeanOrderCreate(BaseModel):
    product_id:       int
    product_name:     str
    quantity:         float
    unit:             Optional[str]  = None
    unit_price:       float
    total_price:      float
    delivery_date:    Optional[date] = None
    note:             Optional[str]  = None
    delivery_address: Optional[str]  = None
    phone:            Optional[str]  = None
    payment_method:   Optional[str]  = None  # "qr" | "cash"


class BeanOrderOut(BaseModel):
    id:            int
    owner_id:      int
    product_id:    int
    product_name:  str
    quantity:      float
    unit:          Optional[str]
    unit_price:    float
    total_price:   float
    status:        str
    delivery_date: Optional[date]
    note:          Optional[str]
    created_at:    Optional[str]

    class Config:
        from_attributes = True


# ── Endpoints ────────────────────────────────────────────────────────
@router.get("", response_model=List[BeanOrderOut])
def list_bean_orders(
    db:    Session   = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    orders = (
        db.query(BeanOrder)
        .filter(BeanOrder.owner_id == owner.id)
        .order_by(BeanOrder.created_at.desc())
        .limit(50)
        .all()
    )
    return [_out(o) for o in orders]


@router.post("", response_model=BeanOrderOut)
async def create_bean_order(
    body:  BeanOrderCreate,
    db:    Session   = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    # QR payments wait for admin confirmation; cash goes straight to processing
    initial_status = "pending_payment" if body.payment_method == "qr" else "processing"

    order = BeanOrder(
        owner_id         = owner.id,
        product_id       = body.product_id,
        product_name     = body.product_name,
        quantity         = body.quantity,
        unit             = body.unit,
        unit_price       = body.unit_price,
        total_price      = body.total_price,
        delivery_date    = body.delivery_date,
        note             = body.note,
        status           = initial_status,
    )
    order.payment_method   = body.payment_method
    order.phone            = body.phone
    order.delivery_address = body.delivery_address
    if body.phone and not owner.phone:
        owner.phone = body.phone
    if body.delivery_address and not owner.address:
        owner.address = body.delivery_address
    db.add(order)
    db.commit()
    db.refresh(order)

    # ── Mirror to admin orders table so dashboard sees it ────────────
    try:
        from ..models.shop import Shop
        from ..models.order import Order
        from sqlalchemy import func as _f

        shop = db.query(Shop).filter(Shop.email == owner.email).first()
        if not shop:
            count = db.query(_f.count(Shop.id)).scalar() or 0
            shop = Shop(
                shop_id=f"FC{str(count + 1).zfill(4)}",
                name=owner.shop_name or owner.email,
                owner_name=owner.shop_name or owner.email,
                phone="—", email=owner.email,
                province="ວຽງຈັນ", status="active",
                tier="bronze", credit_limit=0, credit_used=0,
            )
            db.add(shop)
            db.flush()

        addr_parts = []
        if body.phone or owner.phone:
            addr_parts.append(f"ເບີ: {body.phone or owner.phone}")
        if body.delivery_address or owner.address:
            addr_parts.append(body.delivery_address or owner.address)
        shipping_address = " | ".join(addr_parts) or None

        # QR orders start as "pending" (await payment confirm), cash/others go "confirmed"
        mirror_status = "pending" if order.payment_method == "qr" else "confirmed"
        db.add(Order(
            order_id=f"BO{order.id:06d}",
            shop_id=shop.id,
            amount=int(order.total_price),
            items=[{
                "name": order.product_name,
                "qty": order.quantity,
                "unit": order.unit or "ກີໂລ",
                "unit_price": float(order.unit_price),
                "bean_order_id": order.id,
            }],
            status=mirror_status,
            payment_method=order.payment_method or "cash",
            shipping_address=shipping_address,
        ))
        db.commit()
    except Exception as _e:
        print(f"[WARN] bean→admin mirror: {_e}")
        db.rollback()

    # ── Real-time broadcast to all admin sockets ─────────────────────
    try:
        from ..ws_manager import notify_new_bean_order
        await notify_new_bean_order({
            "id":             order.id,
            "shop_name":      owner.shop_name or owner.email,
            "product_name":   order.product_name,
            "quantity":       order.quantity,
            "unit":           order.unit or "kg",
            "total_price":    order.total_price,
            "payment_method": order.payment_method,
            "status":         order.status,
            "created_at":     str(order.created_at),
        })
    except Exception:
        pass

    return _out(order)


@router.put("/{order_id}/status")
def update_status(
    order_id: int,
    status:   str,
    db:       Session   = Depends(get_db),
    owner:    ShopOwner = Depends(_get_owner),
):
    order = db.query(BeanOrder).filter(
        BeanOrder.id == order_id, BeanOrder.owner_id == owner.id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສັ່ງ")
    order.status = status
    db.commit()
    return {"message": "ອັບເດດສຳເລັດ"}


# ── Helper ───────────────────────────────────────────────────────────
def _out(o: BeanOrder) -> dict:
    return {
        "id":            o.id,
        "owner_id":      o.owner_id,
        "product_id":    o.product_id,
        "product_name":  o.product_name,
        "quantity":      o.quantity,
        "unit":          o.unit,
        "unit_price":    o.unit_price,
        "total_price":   o.total_price,
        "status":        o.status,
        "delivery_date": o.delivery_date,
        "note":          o.note,
        "created_at":    str(o.created_at) if o.created_at else None,
    }
