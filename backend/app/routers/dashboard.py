from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta, date
from ..database import get_db
from ..core.deps import get_current_user
from ..core.timeutil import LAO_TZ, LAO_TZ_NAME, lao_now, lao_month_start
from ..models.admin import Admin
from ..models.shop import Shop
from ..models.application import Application
from ..models.order import Order
from ..models.transaction import Transaction
from ..models.finance import FinanceEntry

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])


def _local_date(col):
    """SQL expression: the Lao-local calendar date of a timestamptz column."""
    return func.date(func.timezone(LAO_TZ_NAME, col))


def _local_month(col):
    """SQL expression: the Lao-local month (as a timestamp) of a timestamptz column."""
    return func.date_trunc("month", func.timezone(LAO_TZ_NAME, col))


@router.get("/kpis")
def get_kpis(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    total_shops = db.query(Shop).filter(Shop.status == "active").count()
    active_credit = db.query(func.sum(Shop.credit_used)).filter(Shop.status == "active").scalar() or 0
    pending_apps = db.query(Application).filter(Application.status == "pending").count()

    now = lao_now()
    month_start = lao_month_start(now)
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

    # Finance summary — entry_date is a plain date chosen by the user, so use the
    # current Lao month boundaries (no tz conversion on the column itself).
    month_start_d = date(now.year, now.month, 1)
    next_m = now.month + 1 if now.month < 12 else 1
    next_y = now.year if now.month < 12 else now.year + 1
    month_end_d = date(next_y, next_m, 1)

    finance_income = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "income",
        FinanceEntry.entry_date >= month_start_d,
        FinanceEntry.entry_date < month_end_d,
    ).scalar() or 0

    finance_expense = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "expense",
        FinanceEntry.entry_date >= month_start_d,
        FinanceEntry.entry_date < month_end_d,
    ).scalar() or 0

    total_capital = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "capital"
    ).scalar() or 0

    return {
        "total_shops": total_shops,
        "new_shops_this_month": new_shops_this_month,
        "active_credit": active_credit,
        "pending_apps": pending_apps,
        "monthly_revenue": monthly_revenue,
        "revenue_change": revenue_change,
        "finance_income": int(finance_income),
        "finance_expense": int(finance_expense),
        "finance_net": int(finance_income) - int(finance_expense),
        "total_capital": int(total_capital),
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

    # Batch-load the shops for the recent payments in one query (was N+1).
    shop_ids = {t.shop_id for t in recent_payments if t.shop_id}
    shops_by_id = {}
    if shop_ids:
        shops_by_id = {s.id: s for s in db.query(Shop).filter(Shop.id.in_(shop_ids)).all()}

    payments_data = []
    for txn in recent_payments:
        shop = shops_by_id.get(txn.shop_id)
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
    now = lao_now()
    start_date = (now - timedelta(days=days - 1)).date()
    start_boundary = datetime(start_date.year, start_date.month, start_date.day, tzinfo=LAO_TZ)

    # Single grouped query (was one query per day). Filter on the raw timestamp
    # so the created_at index is used, then group by the Lao-local date.
    local_date = _local_date(Transaction.created_at)
    rows = (
        db.query(local_date.label("d"), func.sum(Transaction.amount))
        .filter(
            Transaction.type == "credit_use",
            Transaction.created_at >= start_boundary,
        )
        .group_by(local_date)
        .all()
    )
    totals = {r[0]: int(r[1] or 0) for r in rows}

    result = []
    for i in range(days):
        d = start_date + timedelta(days=i)
        result.append({"date": d.strftime("%d/%m"), "amount": totals.get(d, 0)})
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


@router.get("/charts/revenue-expense")
def revenue_expense(
    months: int = Query(12, ge=3, le=24),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user)
):
    now = lao_now()
    first = lao_month_start(now)
    # First month in the window (months-1 back), tz-aware Lao boundary.
    y, m = first.year, first.month
    back = months - 1
    m -= back
    while m <= 0:
        m += 12
        y -= 1
    window_start = datetime(y, m, 1, tzinfo=LAO_TZ)

    # Single grouped query by (Lao month, type) — was 2 queries per month.
    local_month = _local_month(Transaction.created_at)
    rows = (
        db.query(local_month.label("m"), Transaction.type, func.sum(Transaction.amount).label("total"))
        .filter(
            Transaction.created_at >= window_start,
            Transaction.type.in_(["payment", "credit_use"]),
        )
        .group_by(local_month, Transaction.type)
        .all()
    )
    bucket = {}
    for month_ts, ttype, total in rows:
        key = (month_ts.year, month_ts.month)
        bucket.setdefault(key, {})[ttype] = float(total or 0)

    result = []
    for i in range(months):
        month_offset = months - 1 - i
        yy = now.year
        mm = now.month - month_offset
        while mm <= 0:
            mm += 12
            yy -= 1
        vals = bucket.get((yy, mm), {})
        revenue = vals.get("payment", 0.0)
        credit_issued = vals.get("credit_use", 0.0)
        result.append({
            "month": f"{mm:02d}/{yy}",
            "revenue": revenue,
            "credit_issued": credit_issued,
            "profit": revenue - credit_issued,
        })
    return result
