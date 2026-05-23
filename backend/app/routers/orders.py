from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session
from typing import Optional
import math
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.order import Order
from ..models.audit_log import AuditLog
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
    db.add(AuditLog(admin_id=current_user.id, action="order.status_update", entity_type="order", entity_id=order_id, metadata={"status": data.status}))
    db.commit()
    return {"message": "ອັບເດດສະຖານະສຳເລັດ"}


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
    db.add(AuditLog(admin_id=current_user.id, action="order.cancel", entity_type="order", entity_id=order_id, metadata={"reason": data.reason}))
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
