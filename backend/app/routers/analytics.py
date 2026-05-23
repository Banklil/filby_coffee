from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta, timezone
from ..database import get_db
from ..core.deps import get_current_user
from ..models.admin import Admin
from ..models.shop import Shop
from ..models.order import Order
from ..models.transaction import Transaction

router = APIRouter(prefix="/api/analytics", tags=["analytics"])


@router.get("/revenue")
def revenue(
    days: int = Query(90, ge=7, le=365),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user)
):
    now = datetime.now(timezone.utc)
    result = []
    for i in range(days):
        d = (now - timedelta(days=days - 1 - i)).date()
        total = db.query(func.sum(Transaction.amount)).filter(
            func.date(Transaction.created_at) == d,
            Transaction.type == "payment"
        ).scalar() or 0
        result.append({"date": d.strftime("%d/%m"), "amount": total})
    return result


@router.get("/top-products")
def top_products(limit: int = Query(10), db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    from ..models.product import Product
    products = db.query(Product).filter(Product.active == True).order_by(Product.price.desc()).limit(limit).all()
    return [{"name": p.name, "category": p.category, "price": p.price, "stock": float(p.stock_qty)} for p in products]


@router.get("/top-shops")
def top_shops(limit: int = Query(10), db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    shops = db.query(Shop).filter(Shop.status == "active").order_by(Shop.credit_used.desc()).limit(limit).all()
    return [{"name": s.name, "province": s.province, "credit_used": s.credit_used, "tier": s.tier} for s in shops]


@router.get("/geography")
def geography(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    result = db.query(Shop.province, func.count(Shop.id).label("count"), func.sum(Shop.credit_used).label("total_credit")).filter(Shop.status == "active").group_by(Shop.province).all()
    return [{"province": r.province, "count": r.count, "total_credit": r.total_credit or 0} for r in result]


@router.get("/cohort")
def cohort(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    from sqlalchemy import extract
    result = db.query(
        extract("year", Shop.created_at).label("year"),
        extract("month", Shop.created_at).label("month"),
        func.count(Shop.id).label("new_shops"),
        func.sum(Shop.credit_used).label("total_credit"),
    ).group_by("year", "month").order_by("year", "month").all()
    return [{"year": int(r.year), "month": int(r.month), "new_shops": r.new_shops, "total_credit": r.total_credit or 0} for r in result]
