from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import Optional
import math
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.shop import Shop
from ..models.order import Order
from ..models.transaction import Transaction
from ..models.audit_log import AuditLog
from ..schemas.shop import ShopOut, ShopUpdate, CreditLimitUpdate, ShopListResponse

router = APIRouter(prefix="/api/shops", tags=["shops"])


@router.get("", response_model=ShopListResponse)
def list_shops(
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    province: Optional[str] = None,
    status: Optional[str] = None,
    tier: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    q = db.query(Shop)
    if search:
        q = q.filter(or_(Shop.name.ilike(f"%{search}%"), Shop.owner_name.ilike(f"%{search}%"), Shop.shop_id.ilike(f"%{search}%")))
    if province:
        q = q.filter(Shop.province == province)
    if status:
        q = q.filter(Shop.status == status)
    if tier:
        q = q.filter(Shop.tier == tier)
    total = q.count()
    items = q.order_by(Shop.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    return ShopListResponse(items=items, total=total, page=page, limit=limit, pages=math.ceil(total / limit))


@router.get("/{shop_id}", response_model=ShopOut)
def get_shop(shop_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    return shop


@router.put("/{shop_id}", response_model=ShopOut)
def update_shop(shop_id: int, data: ShopUpdate, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(shop, k, v)
    db.add(AuditLog(admin_id=current_user.id, action="shop.update", entity_type="shop", entity_id=shop_id))
    db.commit()
    db.refresh(shop)
    return shop


@router.post("/{shop_id}/suspend")
def suspend_shop(shop_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    shop.status = "suspended"
    db.add(AuditLog(admin_id=current_user.id, action="shop.suspend", entity_type="shop", entity_id=shop_id))
    db.commit()
    return {"message": "ໄດ້ suspend ຮ້ານແລ້ວ"}


@router.post("/{shop_id}/activate")
def activate_shop(shop_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    shop.status = "active"
    db.add(AuditLog(admin_id=current_user.id, action="shop.activate", entity_type="shop", entity_id=shop_id))
    db.commit()
    return {"message": "ໄດ້ activate ຮ້ານແລ້ວ"}


@router.put("/{shop_id}/credit-limit")
def update_credit_limit(shop_id: int, data: CreditLimitUpdate, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    old_limit = shop.credit_limit
    shop.credit_limit = data.new_limit
    db.add(AuditLog(admin_id=current_user.id, action="shop.credit_limit_update", entity_type="shop", entity_id=shop_id, log_metadata={"old": old_limit, "new": data.new_limit, "reason": data.reason}))
    db.commit()
    return {"message": "ອັບເດດວົງເງິນສິນເຊື່ອແລ້ວ", "credit_limit": data.new_limit}


@router.get("/{shop_id}/orders")
def get_shop_orders(shop_id: int, page: int = 1, limit: int = 20, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    total = db.query(Order).filter(Order.shop_id == shop_id).count()
    orders = db.query(Order).filter(Order.shop_id == shop_id).order_by(Order.created_at.desc()).offset((page-1)*limit).limit(limit).all()
    return {"items": orders, "total": total}


@router.get("/{shop_id}/payments")
def get_shop_payments(shop_id: int, page: int = 1, limit: int = 20, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    total = db.query(Transaction).filter(Transaction.shop_id == shop_id).count()
    txns = db.query(Transaction).filter(Transaction.shop_id == shop_id).order_by(Transaction.created_at.desc()).offset((page-1)*limit).limit(limit).all()
    return {"items": txns, "total": total}


@router.get("/{shop_id}/stats")
def get_shop_stats(shop_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    from sqlalchemy import func
    total_orders = db.query(Order).filter(Order.shop_id == shop_id).count()
    total_spent = db.query(func.sum(Order.amount)).filter(Order.shop_id == shop_id, Order.status == "delivered").scalar() or 0
    total_payments = db.query(func.sum(Transaction.amount)).filter(Transaction.shop_id == shop_id, Transaction.type == "payment").scalar() or 0
    return {"total_orders": total_orders, "total_spent": total_spent, "total_payments": total_payments, "credit_available": shop.credit_limit - shop.credit_used}
