from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional
import math
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.order import Order
from ..models.audit_log import AuditLog
from ..core import credit
from ..schemas.order import OrderOut, OrderStatusUpdate, OrderCancelRequest, OrderListResponse

router = APIRouter(prefix="/api/orders", tags=["orders"])


@router.get("", response_model=OrderListResponse)
def list_orders(
    status: Optional[str] = None,
    shop_id: Optional[int] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    q = db.query(Order)
    if status:
        q = q.filter(Order.status == status)
    if shop_id:
        q = q.filter(Order.shop_id == shop_id)
    total = q.count()
    items = q.order_by(Order.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    return OrderListResponse(items=items, total=total, page=page, limit=limit, pages=math.ceil(total / limit))


@router.get("/{order_id}", response_model=OrderOut)
def get_order(order_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສັ່ງຊື້")
    return order


@router.put("/{order_id}/status")
def update_order_status(
    order_id: int, data: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin", "manager")),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສັ່ງຊື້")
    order.status = data.status
    if data.tracking_number:
        order.tracking_number = data.tracking_number
    db.add(AuditLog(admin_id=current_user.id, action="order.status_update", entity_type="order", entity_id=order_id, log_metadata={"status": data.status}))

    # ── Credit bean stock to the shop when a bean order is delivered ──────
    # Bean orders are mirrored here with order_id "BO######" and each item
    # carries its bean_order_id. On delivery we add the ordered kg to the
    # shop owner's balance exactly once (guarded by BeanOrder.stock_credited).
    if data.status == "delivered":
        try:
            _credit_bean_stock_on_delivery(db, order)
        except Exception as _e:
            print(f"[WARN] bean stock credit: {_e}")

        # ຈຸດທີ່ວົງເງິນທີ່ຈອງໄວ້ກາຍເປັນໜີ້ຈິງ ແລະ ນາຬິກາ 30 ມື້ເລີ່ມເດີນ.
        # ບໍ່ຫຸ້ມ try/except — ຖ້າບັນທຶກໜີ້ບໍ່ໄດ້ ຫ້າມໝາຍວ່າສົ່ງເຄື່ອງແລ້ວ.
        credit.capture_for_order(db, order, admin_id=current_user.id)

    elif data.status == "cancelled":
        credit.release_for_order(db, order.id, reason="ຍົກເລີກໂດຍຝ່າຍບໍລິຫານ")

    db.commit()
    return {"message": "ອັບເດດສະຖານະສຳເລັດ"}


def _credit_bean_stock_on_delivery(db: Session, order: Order) -> None:
    from ..models.bean_order import BeanOrder
    from ..models.shop_owner import ShopOwner

    items = order.items or []
    bean_order_ids = [
        it.get("bean_order_id") for it in items
        if isinstance(it, dict) and it.get("bean_order_id")
    ]
    if not bean_order_ids:
        return

    for bo_id in bean_order_ids:
        bo = db.query(BeanOrder).filter(BeanOrder.id == bo_id).first()
        if not bo or bo.stock_credited:
            continue
        owner = db.query(ShopOwner).filter(ShopOwner.id == bo.owner_id).first()
        if not owner:
            continue
        owner.bean_balance_kg = float(owner.bean_balance_kg or 0) + float(bo.quantity or 0)
        bo.stock_credited = True
        bo.status = "delivered"
        bo.delivered_at = func.now()


@router.post("/{order_id}/cancel")
def cancel_order(
    order_id: int, data: OrderCancelRequest,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin", "manager")),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສັ່ງຊື້")
    if order.status in ("delivered", "cancelled"):
        raise HTTPException(status_code=400, detail="ບໍ່ສາມາດຍົກເລີກຄຳສັ່ງຊື້ນີ້ໄດ້")
    order.status = "cancelled"
    credit.release_for_order(db, order.id, reason=data.reason or "ຍົກເລີກຄຳສັ່ງຊື້")
    db.add(AuditLog(admin_id=current_user.id, action="order.cancel", entity_type="order", entity_id=order_id, log_metadata={"reason": data.reason}))
    db.commit()
    return {"message": "ຍົກເລີກຄຳສັ່ງຊື້ແລ້ວ"}


@router.get("/{order_id}/invoice")
def get_invoice(order_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສັ່ງຊື້")
    # Simple PDF placeholder
    content = f"Invoice for Order {order.order_id}\nAmount: {order.amount:,} ກີບ"
    return Response(content=content.encode(), media_type="application/pdf", headers={"Content-Disposition": f"attachment; filename=invoice-{order.order_id}.pdf"})
