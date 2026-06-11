"""
/api/admin/stats — Quick stats for the admin dashboard KPI cards.
Requires Admin JWT (same as existing admin routes).
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date

from ..database import get_db
from ..core.deps import get_current_user
from ..models.admin import Admin
from ..models.shop import Shop
from ..models.credit_application import CreditApplication
from ..models.bean_order import BeanOrder

router = APIRouter(prefix="/api/admin", tags=["admin-stats"])


@router.get("/stats")
def get_stats(
    db:           Session = Depends(get_db),
    current_user: Admin   = Depends(get_current_user),
):
    today = date.today()

    total_shops = db.query(func.count(Shop.id)).scalar() or 0

    pending_credits = db.query(func.count(CreditApplication.id)).filter(
        CreditApplication.status == "pending"
    ).scalar() or 0

    orders_today = db.query(func.count(BeanOrder.id)).filter(
        func.date(BeanOrder.created_at) == today
    ).scalar() or 0

    revenue_today = db.query(func.coalesce(func.sum(BeanOrder.total_price), 0)).filter(
        func.date(BeanOrder.created_at) == today,
        BeanOrder.status != "cancelled",
    ).scalar() or 0

    return {
        "shops":           total_shops,
        "pending_credits": pending_credits,
        "orders_today":    orders_today,
        "revenue_today":   float(revenue_today),
    }
