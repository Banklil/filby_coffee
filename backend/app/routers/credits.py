import os
import secrets
from datetime import timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Header
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..core import credit
from ..core.deps import get_current_user, require_roles
from ..core.timeutil import lao_now
from ..models.admin import Admin
from ..models.audit_log import AuditLog
from ..models.credit import CreditLedger
from ..models.order import Order
from ..models.shop import Shop
from ..models.shop_owner import ShopOwner
from ..models.transaction import Transaction
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/credits", tags=["credits"])


# ── Schemas ──────────────────────────────────────────────────────────
class PaymentRecord(BaseModel):
    shop_id: int
    amount: int = Field(gt=0)
    order_id: Optional[int] = None
    notes: Optional[str] = None


class DepositRecord(BaseModel):
    shop_id: int
    amount: int = Field(gt=0)
    notes: Optional[str] = None


# ── ພາບລວມ ───────────────────────────────────────────────────────────
@router.get("/overview")
def get_overview(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    total_limit = db.scalar(
        select(func.coalesce(func.sum(Shop.credit_limit), 0)).where(Shop.status == "active")
    ) or 0
    total_deposit = db.scalar(
        select(func.coalesce(func.sum(Shop.deposit_balance), 0)).where(Shop.status == "active")
    ) or 0
    # ໜີ້ຈິງມາຈາກ ledger ບໍ່ແມ່ນ Shop.credit_used ທີ່ເປັນພຽງ cache
    total_active = db.scalar(
        select(func.coalesce(func.sum(CreditLedger.signed_amount), 0))
        .join(Shop, Shop.id == CreditLedger.shop_id)
        .where(Shop.status == "active")
    ) or 0

    today = lao_now().date()
    week_later = today + timedelta(days=7)

    due_soon = db.query(Order.shop_id).filter(
        Order.payment_due_date <= week_later,
        Order.payment_due_date >= today,
        Order.paid_at.is_(None),
        Order.status == "delivered",
    ).distinct().count()

    overdue = db.query(Order.shop_id).filter(
        Order.payment_due_date < today,
        Order.paid_at.is_(None),
        Order.status == "delivered",
    ).distinct().count()

    return {
        "total_active_credit": int(total_active),
        "total_limit": int(total_limit),
        "total_deposit": int(total_deposit),
        # ຄວາມສ່ຽງສຸດທິ = ໜີ້ທັງໝົດ ລົບ ມັດຈຳທີ່ຖືໄວ້
        "net_exposure": int(total_active) - int(total_deposit),
        "due_soon_count": due_soon,
        "overdue_count": overdue,
        "grace_days": credit.GRACE_DAYS,
        "monthly_rate": credit.MONTHLY_RATE,
    }


@router.get("/due-soon")
def get_due_soon(days: int = Query(7, ge=1, le=30), db: Session = Depends(get_db),
                 current_user: Admin = Depends(get_current_user)):
    today = lao_now().date()
    cutoff = today + timedelta(days=days)
    rows = db.query(Order, Shop).join(Shop, Shop.id == Order.shop_id).filter(
        Order.payment_due_date <= cutoff,
        Order.payment_due_date >= today,
        Order.paid_at.is_(None),
        Order.status == "delivered",
    ).order_by(Order.payment_due_date).all()

    return [{
        "order_id": o.order_id,
        "shop_id": s.id,
        "shop_name": s.name,
        "amount": int(o.amount or 0),
        "due_date": o.payment_due_date,
        "days_left": (o.payment_due_date - today).days,
        "phone": s.phone,
    } for o, s in rows]


@router.get("/overdue")
def get_overdue(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    today = lao_now().date()
    rows = db.query(Order, Shop).join(Shop, Shop.id == Order.shop_id).filter(
        Order.payment_due_date < today,
        Order.paid_at.is_(None),
        Order.status == "delivered",
    ).order_by(Order.payment_due_date).all()

    out = []
    for o, s in rows:
        days_overdue = (today - o.payment_due_date).days
        # ດອກເບ້ຍທີ່ບັນທຶກໄວ້ຈິງ ບໍ່ແມ່ນຄິດສົດຕອນສະແດງຜົນ
        accrued = db.scalar(
            select(func.coalesce(func.sum(CreditLedger.signed_amount), 0))
            .where(CreditLedger.order_id == o.id, CreditLedger.entry_type == "interest")
        ) or 0
        out.append({
            "order_id": o.order_id,
            "shop_id": s.id,
            "shop_name": s.name,
            "amount": int(o.amount or 0),
            "due_date": o.payment_due_date,
            "days_overdue": days_overdue,
            "interest": int(accrued),
            "total_due": int(o.amount or 0) + int(accrued),
            "credit_status": s.credit_status,
            "phone": s.phone,
        })
    return out


# ── ບັນຊີຂອງແຕ່ລະຮ້ານ ─────────────────────────────────────────────────
@router.get("/shop/{shop_id}")
def get_shop_credit(shop_id: int, db: Session = Depends(get_db),
                    current_user: Admin = Depends(get_current_user)):
    shop = db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")
    return credit.snapshot(db, shop)


@router.get("/shop/{shop_id}/ledger")
def get_shop_ledger(shop_id: int, limit: int = Query(100, ge=1, le=500),
                    db: Session = Depends(get_db),
                    current_user: Admin = Depends(get_current_user)):
    rows = db.scalars(
        select(CreditLedger)
        .where(CreditLedger.shop_id == shop_id)
        .order_by(CreditLedger.created_at.desc(), CreditLedger.id.desc())
        .limit(limit)
    ).all()
    return [{
        "id": r.id,
        "amount": int(r.signed_amount),
        "type": r.entry_type,
        "order_id": r.order_id,
        "description": r.description,
        "created_at": r.created_at,
    } for r in rows]


# ── ຮັບຊຳລະ ──────────────────────────────────────────────────────────
@router.post("/payment")
def record_payment(data: PaymentRecord, db: Session = Depends(get_db),
                   current_user: Admin = Depends(require_roles("super_admin", "manager", "accountant"))):
    shop = db.get(Shop, data.shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")

    stamp = lao_now().strftime("%Y%m%d%H%M%S%f")
    try:
        unallocated = credit.post_payment(
            db, shop.id, data.amount,
            admin_id=current_user.id,
            idem=f"pay:{shop.id}:{stamp}",
            note=data.notes or "ຈ່າຍຄືນສິນເຊື່ອ",
        )
    except credit.CreditError as e:
        raise HTTPException(status_code=400, detail=str(e))

    db.add(Transaction(
        shop_id=shop.id, type="payment", amount=data.amount,
        related_order_id=data.order_id,
        description=data.notes or "ຈ່າຍຄືນສິນເຊື່ອ",
    ))
    db.add(AuditLog(
        admin_id=current_user.id, action="credit.payment",
        entity_type="shop", entity_id=shop.id,
        log_metadata={"amount": data.amount},
    ))
    db.commit()

    snap = credit.snapshot(db, shop)
    return {
        "message": "ບັນທຶກການຈ່າຍສຳເລັດ",
        "unallocated": unallocated,
        **snap,
    }


# ── ເງິນມັດຈຳ ─────────────────────────────────────────────────────────
@router.post("/deposit")
def record_deposit(data: DepositRecord, db: Session = Depends(get_db),
                   current_user: Admin = Depends(require_roles("super_admin", "manager", "accountant"))):
    """ຮັບເງິນມັດຈຳ — ບໍ່ແມ່ນການຊຳລະໜີ້ ຈຶ່ງບໍ່ແຕະ ledger ໜີ້."""
    shop = db.get(Shop, data.shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")

    stamp = lao_now().strftime("%Y%m%d%H%M%S%f")
    try:
        credit.add_deposit(
            db, shop.id, data.amount, admin_id=current_user.id,
            idem=f"dep:{shop.id}:{stamp}", reason=data.notes or "ຮັບເງິນມັດຈຳ",
        )
    except credit.CreditError as e:
        raise HTTPException(status_code=400, detail=str(e))

    db.add(AuditLog(
        admin_id=current_user.id, action="credit.deposit_received",
        entity_type="shop", entity_id=shop.id,
        log_metadata={"amount": data.amount},
    ))
    db.commit()
    return {"message": "ບັນທຶກເງິນມັດຈຳສຳເລັດ", **credit.snapshot(db, shop)}


@router.post("/deposit/{shop_id}/refund")
def refund_deposit(shop_id: int, db: Session = Depends(get_db),
                   current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    """ຄືນມັດຈຳ — ໄດ້ສະເພາະເມື່ອບໍ່ມີໜີ້ ແລະ ບໍ່ມີວົງເງິນຈອງຄ້າງ."""
    shop = db.get(Shop, shop_id)
    if not shop:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຮ້ານ")

    stamp = lao_now().strftime("%Y%m%d%H%M%S%f")
    try:
        amount = credit.refund_deposit(
            db, shop.id, admin_id=current_user.id,
            idem=f"deprefund:{shop.id}:{stamp}",
        )
    except credit.CreditError as e:
        raise HTTPException(status_code=400, detail=str(e))

    db.add(AuditLog(
        admin_id=current_user.id, action="credit.deposit_refunded",
        entity_type="shop", entity_id=shop.id, log_metadata={"amount": amount},
    ))
    db.commit()
    return {"message": f"ຄືນເງິນມັດຈຳ {amount:,} ກີບ", "refunded": amount}


# ── ຝັ່ງຮ້ານ: ເບິ່ງວົງເງິນຕົນເອງ ────────────────────────────────────
@router.get("/me", tags=["merchant"])
def my_credit(db: Session = Depends(get_db), owner: ShopOwner = Depends(_get_owner)):
    """ໃຫ້ແອັບສະແດງວົງເງິນຄົງເຫຼືອ ແລະ ໜີ້ຄ້າງຂອງຮ້ານຕົນເອງ."""
    shop = credit.shop_for_owner(db, owner, create=False)
    if not shop:
        return {
            "approved_limit": 0, "effective_limit": 0, "balance": 0, "held": 0,
            "available": 0, "deposit": 0, "net_exposure": 0,
            "credit_status": "good", "grace_days": credit.GRACE_DAYS,
            "monthly_rate": credit.MONTHLY_RATE, "next_due_date": None,
        }

    snap = credit.snapshot(db, shop)
    today = lao_now().date()
    next_due = db.scalar(
        select(func.min(Order.payment_due_date)).where(
            Order.shop_id == shop.id,
            Order.paid_at.is_(None),
            Order.payment_due_date.isnot(None),
            Order.status == "delivered",
        )
    )
    snap["next_due_date"] = next_due
    snap["days_until_due"] = (next_due - today).days if next_due else None
    db.commit()      # shop_for_owner ອາດຜູກ owner_id ໃຫ້
    return snap


# ── Job ປະຈຳວັນ ──────────────────────────────────────────────────────
@router.post("/run-daily")
def run_daily_job(
    db: Session = Depends(get_db),
    x_cron_secret: Optional[str] = Header(default=None, alias="X-Cron-Secret"),
):
    """ຄິດດອກເບ້ຍ ແລະ ປັບສະຖານະ. ໃຫ້ cron ພາຍນອກເອີ້ນວັນລະຄັ້ງ.

    ຢືນຢັນຕົວດ້ວຍ header X-Cron-Secret ທຽບກັບ env CRON_SECRET.
    ຖ້າບໍ່ໄດ້ຕັ້ງ CRON_SECRET ໄວ້ endpoint ນີ້ຈະປິດຢູ່.
    """
    # .strip() ຍ້ອນການວາງຄ່າໃສ່ໜ້າຈໍ Railway ມັກຕິດ newline ມານຳ ເຊິ່ງເຮັດໃຫ້
    # secret ທີ່ຖືກຕ້ອງຜ່ານບໍ່ໄດ້ ແລະ ຫາສາເຫດຍາກຫຼາຍ.
    expected = (os.getenv("CRON_SECRET") or "").strip()
    if not expected:
        raise HTTPException(status_code=503, detail="ຍັງບໍ່ໄດ້ຕັ້ງ CRON_SECRET")
    # compare_digest ກັນການເດົາ secret ດ້ວຍການວັດເວລາຕອບ
    if not secrets.compare_digest((x_cron_secret or "").strip(), expected):
        raise HTTPException(status_code=401, detail="ບໍ່ໄດ້ຮັບອະນຸຍາດ")

    from ..jobs.credit_daily import run_daily
    return run_daily(db)


@router.post("/run-daily/manual")
def run_daily_manual(db: Session = Depends(get_db),
                     current_user: Admin = Depends(require_roles("super_admin"))):
    """ແລ່ນ job ດ້ວຍມືຈາກ dashboard — ໃຊ້ຕອນທົດສອບ ຫຼື cron ລົ້ມ."""
    from ..jobs.credit_daily import run_daily
    stats = run_daily(db)
    db.add(AuditLog(admin_id=current_user.id, action="credit.run_daily",
                    entity_type="system", entity_id=0, log_metadata=stats))
    db.commit()
    return stats
