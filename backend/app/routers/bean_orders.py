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
    product_id:    int
    product_name:  str
    quantity:      float
    unit_price:    float
    total_price:   float
    delivery_date: Optional[date] = None
    note:          Optional[str]  = None


class BeanOrderOut(BaseModel):
    id:            int
    owner_id:      int
    product_id:    int
    product_name:  str
    quantity:      float
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
    order = BeanOrder(
        owner_id      = owner.id,
        product_id    = body.product_id,
        product_name  = body.product_name,
        quantity      = body.quantity,
        unit_price    = body.unit_price,
        total_price   = body.total_price,
        delivery_date = body.delivery_date,
        note          = body.note,
        status        = "processing",
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    # ── Real-time broadcast to all admin sockets ─────────────────────
    try:
        from ..ws_manager import notify_new_bean_order
        await notify_new_bean_order({
            "id":           order.id,
            "shop_name":    owner.shop_name,
            "product_name": order.product_name,
            "quantity":     order.quantity,
            "total_price":  order.total_price,
            "created_at":   str(order.created_at),
        })
    except Exception:
        pass  # WebSocket errors must never break the HTTP response

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
        "unit_price":    o.unit_price,
        "total_price":   o.total_price,
        "status":        o.status,
        "delivery_date": o.delivery_date,
        "note":          o.note,
        "created_at":    str(o.created_at) if o.created_at else None,
    }
