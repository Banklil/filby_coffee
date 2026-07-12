"""
/api/merchant/daily-report — Daily financial report for merchant accounts.

Closing Balance formula:  prev_balance + receipts - payments
Data is sourced from bean_orders_merchant (receipts proxy) and
a simple merchant_transactions table (created lazily on first write).
For now we return a sensible structure from existing data.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from datetime import date, datetime, timedelta
from typing import Optional

from ..database import get_db
from ..models.shop_owner import ShopOwner
from ..models.bean_order import BeanOrder
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/merchant", tags=["merchant-report"])


@router.get("/daily-report")
def daily_report(
    report_date: Optional[date] = Query(None),
    db:    Session   = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    today      = report_date or date.today()
    yesterday  = today - timedelta(days=1)

    # ── Receipts: total of delivered bean orders today ───────────────
    receipts = db.query(func.coalesce(func.sum(BeanOrder.total_price), 0)).filter(
        BeanOrder.owner_id == owner.id,
        func.date(BeanOrder.created_at) == today,
        BeanOrder.status.in_(["processing", "confirmed", "delivered"]),
    ).scalar() or 0

    # ── Payments: cancelled / refund orders (simulated) ──────────────
    payments = db.query(func.coalesce(func.sum(BeanOrder.total_price), 0)).filter(
        BeanOrder.owner_id == owner.id,
        func.date(BeanOrder.created_at) == today,
        BeanOrder.status == "cancelled",
    ).scalar() or 0

    # ── Previous day receipts (used as prev_balance proxy) ───────────
    prev_balance = db.query(func.coalesce(func.sum(BeanOrder.total_price), 0)).filter(
        BeanOrder.owner_id == owner.id,
        func.date(BeanOrder.created_at) == yesterday,
        BeanOrder.status.in_(["processing", "confirmed", "delivered"]),
    ).scalar() or 0

    # ── Transaction count ─────────────────────────────────────────────
    tx_count = db.query(func.count(BeanOrder.id)).filter(
        BeanOrder.owner_id == owner.id,
        func.date(BeanOrder.created_at) == today,
    ).scalar() or 0

    # ── Weekly receipts for the bar chart (last 7 days) ──────────────
    weekly_receipts = []
    weekly_payments = []
    for i in range(6, -1, -1):
        d = today - timedelta(days=i)
        r = db.query(func.coalesce(func.sum(BeanOrder.total_price), 0)).filter(
            BeanOrder.owner_id == owner.id,
            func.date(BeanOrder.created_at) == d,
            BeanOrder.status != "cancelled",
        ).scalar() or 0
        p = db.query(func.coalesce(func.sum(BeanOrder.total_price), 0)).filter(
            BeanOrder.owner_id == owner.id,
            func.date(BeanOrder.created_at) == d,
            BeanOrder.status == "cancelled",
        ).scalar() or 0
        weekly_receipts.append(float(r))
        weekly_payments.append(float(p))

    # ── Transactions list ─────────────────────────────────────────────
    orders_today = db.query(BeanOrder).filter(
        BeanOrder.owner_id == owner.id,
        func.date(BeanOrder.created_at) == today,
    ).order_by(BeanOrder.created_at.desc()).all()

    transactions = [
        {
            "id":          o.id,
            "type":        "receipt" if o.status != "cancelled" else "payment",
            "amount":      o.total_price,
            "description": f"ສັ່ງ {o.product_name} × {o.quantity} kg",
            "reference":   f"BO-{o.id:04d}",
            "status":      "paid" if o.status == "delivered" else ("unpaid" if o.status == "cancelled" else "partial"),
            "created_at":  o.created_at.isoformat() if o.created_at else None,
        }
        for o in orders_today
    ]

    closing_balance = float(prev_balance) + float(receipts) - float(payments)

    return {
        "summary": {
            "report_date":        str(today),
            "prev_balance":       float(prev_balance),
            "receipts":           float(receipts),
            "payments":           float(payments),
            "debt_payment":       0.0,
            "transaction_count":  tx_count,
            "weekly_receipts":    weekly_receipts,
            "weekly_payments":    weekly_payments,
            "closing_balance":    closing_balance,
        },
        "transactions": transactions,
    }
