"""
/api/orders/beans — Bean order endpoints for merchant (ShopOwner) accounts.
Real-time: on POST, broadcasts new_bean_order to all connected admin sockets.
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date
from uuid import uuid4

from ..database import get_db
from ..models.bean_order import BeanOrder
from ..models.shop_owner import ShopOwner
from ..models.product import Product
from ..core import credit
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/orders/beans", tags=["bean-orders"])


# ── Schemas ─────────────────────────────────────────────────────────
class BeanOrderCreate(BaseModel):
    """ລາຄາບໍ່ຮັບຈາກ client ອີກແລ້ວ.

    ກ່ອນນີ້ unit_price/total_price ມາຈາກ request body ໂດຍບໍ່ມີການກວດ —
    ໝາຍຄວາມວ່າໃຜກໍ່ສັ່ງກາເຟ 100 ກິໂລ ໃນລາຄາ 1 ກີບໄດ້. ດຽວນີ້ຄິດຈາກ
    ຕາຕະລາງ products ຢູ່ server ສະເໝີ.
    """
    product_id:       int
    quantity:         float = Field(gt=0, le=1000)
    delivery_date:    Optional[date] = None
    note:             Optional[str]  = Field(default=None, max_length=1000)
    delivery_address: Optional[str]  = Field(default=None, max_length=500)
    phone:            Optional[str]  = Field(default=None, max_length=50)
    payment_method:   str = Field(default="cash", pattern="^(qr|cash|credit)$")


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
    body:    BeanOrderCreate,
    request: Request,
    db:      Session   = Depends(get_db),
    owner:   ShopOwner = Depends(_get_owner),
):
    from ..models.order import Order

    # ── 1. ລາຄາມາຈາກຖານຂໍ້ມູນເທົ່ານັ້ນ ──────────────────────────────
    product = db.query(Product).filter(Product.id == body.product_id).first()
    if not product or product.active is False:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບສິນຄ້າ ຫຼື ສິນຄ້າຖືກປິດຂາຍແລ້ວ")

    unit_price  = int(product.price)
    total_price = int(round(unit_price * body.quantity))
    if total_price <= 0:
        raise HTTPException(status_code=400, detail="ຍອດສັ່ງຊື້ບໍ່ຖືກຕ້ອງ")

    shop = credit.shop_for_owner(db, owner)

    # ── 2. ຈ່າຍດ້ວຍສິນເຊື່ອ → ຕ້ອງຈອງວົງເງິນກ່ອນ ────────────────────
    hold = None
    if body.payment_method == "credit":
        idem = request.headers.get("Idempotency-Key") or f"bean:{owner.id}:{uuid4()}"
        try:
            hold = credit.reserve(db, shop.id, total_price, idem=idem)
        except credit.CreditBlocked as e:
            raise HTTPException(status_code=403, detail={
                "code": "credit_blocked",
                "status": e.status,
                "message": "ບັນຊີສິນເຊື່ອຖືກລະງັບ ກະລຸນາຊຳລະໜີ້ຄ້າງກ່ອນ",
            })
        except credit.CreditLimitExceeded as e:
            raise HTTPException(status_code=402, detail={
                "code": "credit_limit_exceeded",
                "requested": e.requested,
                "available": e.available,
                "message": (
                    f"ວົງເງິນຄົງເຫຼືອ {e.available:,} ກີບ "
                    f"ບໍ່ພໍສຳລັບຍອດ {e.requested:,} ກີບ"
                ),
            })
        except credit.CreditError as e:
            raise HTTPException(status_code=400, detail=str(e))

    # ── 3. ສ້າງ order ພ້ອມ mirror ໃນ transaction ດຽວກັນ ─────────────
    #     ບໍ່ມີ try/except ກືນ error ອີກແລ້ວ: ຖ້າ mirror ລົ້ມ ຄຳສັ່ງກໍ່ຕ້ອງລົ້ມນຳ
    #     ບໍ່ດັ່ງນັ້ນລູກຄ້າໄດ້ເຄື່ອງ ແຕ່ໜີ້ບໍ່ຖືກບັນທຶກ.
    initial_status = "pending_payment" if body.payment_method == "qr" else "processing"

    order = BeanOrder(
        owner_id         = owner.id,
        product_id       = product.id,
        product_name     = product.name,
        quantity         = body.quantity,
        unit             = product.unit or "ກີໂລ",
        unit_price       = unit_price,
        total_price      = total_price,
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
    db.flush()

    addr_parts = []
    if body.phone or owner.phone:
        addr_parts.append(f"ເບີ: {body.phone or owner.phone}")
    if body.delivery_address or owner.address:
        addr_parts.append(body.delivery_address or owner.address)
    shipping_address = " | ".join(addr_parts) or None

    # QR orders start as "pending" (await payment confirm), cash/credit go "confirmed"
    mirror_status = "pending" if body.payment_method == "qr" else "confirmed"
    mirror = Order(
        order_id=f"BO{order.id:06d}",
        shop_id=shop.id,
        amount=total_price,
        items=[{
            "name": order.product_name,
            "qty": order.quantity,
            "unit": order.unit,
            "unit_price": float(unit_price),
            "bean_order_id": order.id,
        }],
        status=mirror_status,
        payment_method=body.payment_method,
        shipping_address=shipping_address,
    )
    db.add(mirror)
    db.flush()

    if hold is not None:
        hold.order_id = mirror.id      # ຜູກການຈອງກັບ order ເພື່ອຕັດຕອນສົ່ງເຄື່ອງ

    db.commit()
    db.refresh(order)

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
    """ຮ້ານຍົກເລີກຄຳສັ່ງຂອງຕົນເອງໄດ້ເທົ່ານັ້ນ.

    ກ່ອນນີ້ຮັບ status ຫຍັງກໍ່ໄດ້ — ຮ້ານຈຶ່ງໝາຍ "delivered" ໃສ່ຄຳສັ່ງຕົນເອງໄດ້.
    ການປ່ຽນສະຖານະອື່ນເປັນສິດຂອງຝ່າຍບໍລິຫານຜ່ານ /api/orders/{id}/status.
    """
    from ..models.order import Order

    if status != "cancelled":
        raise HTTPException(
            status_code=403,
            detail="ຮ້ານຍົກເລີກຄຳສັ່ງໄດ້ເທົ່ານັ້ນ — ສະຖານະອື່ນຕ້ອງໃຫ້ຝ່າຍບໍລິຫານດຳເນີນການ",
        )

    order = db.query(BeanOrder).filter(
        BeanOrder.id == order_id, BeanOrder.owner_id == owner.id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສັ່ງ")
    if order.status in ("delivered", "cancelled"):
        raise HTTPException(status_code=400, detail="ຄຳສັ່ງນີ້ຍົກເລີກບໍ່ໄດ້ແລ້ວ")

    order.status = "cancelled"

    # ຄືນວົງເງິນທີ່ຈອງໄວ້ ແລະ ປິດ order ຝັ່ງບໍລິຫານນຳ
    mirror = db.query(Order).filter(Order.order_id == f"BO{order.id:06d}").first()
    if mirror:
        mirror.status = "cancelled"
        credit.release_for_order(db, mirror.id, reason="ຮ້ານຍົກເລີກຄຳສັ່ງ")

    db.commit()
    return {"message": "ຍົກເລີກຄຳສັ່ງແລ້ວ"}


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
