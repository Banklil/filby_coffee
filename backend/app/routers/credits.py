from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, timedelta
from pydantic import BaseModel
from typing import Optional
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.shop import Shop
from ..models.transaction import Transaction
from ..models.order import Order
from ..models.audit_log import AuditLog

router = APIRouter(prefix="/api/credits", tags=["credits"])


class PaymentRecord(BaseModel):
    shop_id: int
    amount: int
    order_id: Optional[int] = None
    notes: Optional[str] = None


@router.get("/overview")
def get_overview(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    total_active = db.query(func.sum(Shop.credit_used)).filter(Shop.status == "active").scalar() or 0
    total_limit = db.query(func.sum(Shop.credit_limit)).filter(Shop.status == "active").scalar() or 0
    today = date.today()
    week_later = today + timedelta(days=7)

    due_soon = db.query(Shop).join(Order, Order.shop_id == Shop.id).filter(
        Order.payment_due_date <= week_later,
        Order.payment_due_date >= today,
        Order.paid_at == None,
        Order.status == "delivered",
    ).distinct().count()

    overdue = db.query(Shop).join(Order, Order.shop_id == Shop.id).filter(
        Order.payment_due_date < today,
        Order.paid_at == None,
        Order.status == "delivered",
    ).distinct().count()

    return {"total_active_credit": total_active, "total_limit": total_limit, "due_soon_count": due_soon, "overdue_count": overdue}


@router.get("/due-soon")
def get_due_soon(days: int = Query(7, ge=1, le=30), db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    today = date.today()
    cutoff = today + timedelta(days=days)
    orders = db.query(Order).filter(
        Order.payment_due_date <= cutoff,
        Order.payment_due_date >= today,
        Order.paid_at == None,
        Order.status == "delivered",
    ).order_by(Order.payment_due_date).all()
    result = []
    for o in orders:
        shop = db.query(Shop).filter(Shop.id == o.shop_id).first()
        result.append({"order_id": o.order_id, "shop_name": shop.name if shop else "", "amount": o.amount, "due_date": o.payment_due_date, "phone": shop.phone if shop else ""})
    return result


@router.get("/overdue")
def get_overdue(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    today = date.today()
    orders = db.query(Order).filter(
        Order.payment_due_date < today,
        Order.paid_at == None,
        Order.status == "delivered",
    ).order_by(Order.payment_due_date).all()
    result = []
    for o in orders:
        shop = db.query(Shop).filter(Shop.id == o.shop_id).first()
        days_overdue = (today - o.payment_due_date).days
        interest = int(o.amount * 0.015 * (days_overdue / 30))
        result.append({"order_id": o.order_id, "shop_name": shop.name if shop else "", "amount": o.amount, "due_date": o.payment_due_date, "days_overdue": days_overdue, "interest": interest, "phone": shop.phone if shop else ""})
    return result


@router.post("/payment")
def record_payment(data: PaymentRecord, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager", "accountant"))):
    shop = db.query(Shop).filter(Shop.id == data.shop_id).first()
    if not shop:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")

    shop.credit_used = max(0, shop.credit_used - data.amount)
    txn = Transaction(
        shop_id=data.shop_id,
        type="payment",
        amount=data.amount,
        related_order_id=data.order_id,
        description=data.notes or "ຈ່າຍຄືນສິນເຊື່ອ",
    )
    db.add(txn)
    db.add(AuditLog(admin_id=current_user.id, action="credit.payment", entity_type="shop", entity_id=data.shop_id, metadata={"amount": data.amount}))
    db.commit()
    return {"message": "ບັນທຶກການຈ່າຍສຳເລັດ", "new_credit_used": shop.credit_used}
