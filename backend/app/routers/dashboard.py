from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from datetime import datetime, timedelta, timezone, date
from ..database import get_db
from ..core.deps import get_current_user
from ..models.admin import Admin
from ..models.shop import Shop
from ..models.application import Application
from ..models.order import Order
from ..models.transaction import Transaction

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])


@router.get("/kpis")
def get_kpis(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    total_shops = db.query(Shop).filter(Shop.status == "active").count()
    active_credit = db.query(func.sum(Shop.credit_used)).filter(Shop.status == "active").scalar() or 0
    pending_apps = db.query(Application).filter(Application.status == "pending").count()

    now = datetime.now(timezone.utc)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    monthly_revenue = db.query(func.sum(Transaction.amount)).filter(
        Transaction.type == "payment",
        Transaction.created_at >= month_start
    ).scalar() or 0

    prev_month_start = (month_start - timedelta(days=1)).replace(day=1)
    prev_revenue = db.query(func.sum(Transaction.amount)).filter(
        Transaction.type == "payment",
        Transaction.created_at >= prev_month_start,
        Transaction.created_at < month_start,
    ).scalar() or 0

    new_shops_this_month = db.query(Shop).filter(Shop.created_at >= month_start).count()

    revenue_change = 0
    if prev_revenue > 0:
        revenue_change = round(((monthly_revenue - prev_revenue) / prev_revenue) * 100, 1)

    return {
        "total_shops": total_shops,
        "new_shops_this_month": new_shops_this_month,
        "active_credit": active_credit,
        "pending_apps": pending_apps,
        "monthly_revenue": monthly_revenue,
        "revenue_change": revenue_change,
    }


@router.get("/recent")
def get_recent(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    recent_apps = db.query(Application).filter(Application.status == "pending").order_by(
        Application.created_at.desc()
    ).limit(5).all()

    recent_payments = db.query(Transaction).filter(Transaction.type == "payment").order_by(
        Transaction.created_at.desc()
    ).limit(5).all()

    apps_data = []
    for app in recent_apps:
        shop_data = app.shop_data or {}
        apps_data.append({
            "type": "new_application",
            "id": app.id,
            "ref_id": app.ref_id,
            "shop_name": shop_data.get("shopName", "ບໍ່ລະບຸ"),
            "credit_requested": app.credit_requested,
            "created_at": app.created_at,
        })

    payments_data = []
    for txn in recent_payments:
        shop = db.query(Shop).filter(Shop.id == txn.shop_id).first()
        payments_data.append({
            "type": "payment",
            "id": txn.id,
            "shop_name": shop.name if shop else "ບໍ່ລະບຸ",
            "amount": txn.amount,
            "created_at": txn.created_at,
        })

    overdue_shops = db.query(Shop).filter(
        Shop.credit_used > 0,
        Shop.status == "active"
    ).limit(5).all()
    overdue_data = [{"type": "overdue", "id": s.id, "shop_name": s.name, "credit_used": s.credit_used} for s in overdue_shops]

    return {"applications": apps_data, "payments": payments_data, "overdue": overdue_data}


@router.get("/charts/credit-trend")
def credit_trend(
    days: int = Query(30, ge=7, le=90),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user)
):
    now = datetime.now(timezone.utc)
    result = []
    for i in range(days):
        d = (now - timedelta(days=days - 1 - i)).date()
        total = db.query(func.sum(Transaction.amount)).filter(
            func.date(Transaction.created_at) == d,
            Transaction.type == "credit_use"
        ).scalar() or 0
        result.append({"date": d.strftime("%d/%m"), "amount": total})
    return result


@router.get("/charts/top-shops")
def top_shops(
    limit: int = Query(10, ge=1, le=20),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user)
):
    shops = db.query(Shop).filter(Shop.status == "active").order_by(
        Shop.credit_used.desc()
    ).limit(limit).all()
    return [{"name": s.name, "credit_used": s.credit_used, "tier": s.tier} for s in shops]
