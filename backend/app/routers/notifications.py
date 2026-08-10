"""ການເຕືອນສຳລັບຮ້ານ — ສ້າງຈາກຂໍ້ມູນຈິງ ບໍ່ແມ່ນຕາຕະລາງແຍກ.

ເປັນຫຍັງບໍ່ເກັບເປັນຕາຕະລາງ: ທຸກເລື່ອງທີ່ຄວນເຕືອນ (ໜີ້ໃກ້ຄົບກຳນົດ, ຄຳສັ່ງຖືກສົ່ງ,
ເມັດກາເຟໃກ້ໝົດ) ຄິດອອກຈາກຂໍ້ມູນທີ່ມີຢູ່ແລ້ວໄດ້ໝົດ. ການເກັບຊ້ຳຈະສ້າງບັນຫາ
ຂໍ້ມູນບໍ່ຕົງກັນ ແລະ ຕ້ອງມີ job ຄອຍສ້າງແຖວ. ອ່ານສົດຈຶ່ງຖືກຕ້ອງສະເໝີ.

ສະຖານະ "ອ່ານແລ້ວ" ເກັບເປັນເວລາດຽວ (shop_owners.notifications_seen_at)
ແລ້ວນັບອັນທີ່ໃໝ່ກວ່ານັ້ນເປັນຍັງບໍ່ໄດ້ອ່ານ.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core import credit
from ..core.timeutil import lao_now
from ..database import get_db
from ..models.bean_order import BeanOrder
from ..models.order import Order
from ..models.shop_owner import ShopOwner
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/shop/notifications", tags=["notifications"])

LOW_STOCK_KG = 3.0
RECENT_ORDER_DAYS = 14


def _at(dt) -> str:
    """ISO string ທີ່ client ອ່ານໄດ້ ແລະ ໃຊ້ຮຽງລຳດັບໄດ້."""
    if dt is None:
        return lao_now().isoformat()
    if isinstance(dt, datetime):
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.isoformat()
    # date → ເອົາທ່ຽງຄືນຂອງມື້ນັ້ນ
    return datetime(dt.year, dt.month, dt.day, tzinfo=timezone.utc).isoformat()


def _build(db: Session, owner: ShopOwner) -> list[dict]:
    items: list[dict] = []
    today = lao_now().date()
    shop = credit.shop_for_owner(db, owner, create=False)

    # ── ສິນເຊື່ອ ──────────────────────────────────────────────────────
    if shop:
        snap = credit.snapshot(db, shop)

        if snap["awaiting_deposit"]:
            items.append({
                "id": f"deposit:{shop.id}",
                "type": "credit",
                "severity": "warning",
                "title": "ຕ້ອງວາງມັດຈຳກ່ອນໃຊ້ສິນເຊື່ອ",
                "body": f"ວົງເງິນ {snap['approved_limit']:,} ກີບ ຖືກອະນຸມັດແລ້ວ — "
                        f"ວາງມັດຈຳ {snap['required_deposit']:,} ກີບ ຈຶ່ງເລີ່ມສັ່ງໄດ້",
                "created_at": _at(shop.updated_at),
                "action": "credit",
            })

        if snap["credit_status"] in ("on_hold", "suspended", "defaulted"):
            label = {"on_hold": "ລະງັບການສັ່ງຊື້ຊົ່ວຄາວ",
                     "suspended": "ບັນຊີສິນເຊື່ອຖືກລະງັບ",
                     "defaulted": "ບັນຊີຢູ່ໃນສະຖານະຜິດນັດຊຳລະ"}[snap["credit_status"]]
            items.append({
                "id": f"status:{shop.id}:{snap['credit_status']}",
                "type": "credit",
                "severity": "danger",
                "title": label,
                "body": f"ຍອດຄ້າງຊຳລະ {snap['balance']:,} ກີບ — "
                        f"ຊຳລະເພື່ອເປີດການສັ່ງຊື້ຄືນ",
                "created_at": _at(shop.updated_at),
                "action": "credit",
            })

        unpaid = db.scalars(
            select(Order).where(
                Order.shop_id == shop.id,
                Order.paid_at.is_(None),
                Order.payment_due_date.isnot(None),
                Order.status == "delivered",
            ).order_by(Order.payment_due_date)
        ).all()

        for o in unpaid:
            days = (o.payment_due_date - today).days
            if days < 0:
                late = -days
                interest = int(round(int(o.amount or 0) * credit.DAILY_RATE * late))
                items.append({
                    "id": f"overdue:{o.id}:{today.isoformat()}",
                    "type": "credit",
                    "severity": "danger",
                    "title": f"ເກີນກຳນົດຊຳລະ {late} ມື້",
                    "body": f"ໃບບິນ {o.order_id} · {int(o.amount or 0):,} ກີບ "
                            f"+ ດອກເບ້ຍ {interest:,} ກີບ",
                    "created_at": _at(o.payment_due_date),
                    "action": "credit",
                })
            elif days <= 7:
                when = "ມື້ນີ້" if days == 0 else f"ອີກ {days} ມື້"
                items.append({
                    "id": f"duesoon:{o.id}",
                    "type": "credit",
                    "severity": "warning" if days <= 3 else "info",
                    "title": f"ຄົບກຳນົດຊຳລະ {when}",
                    "body": f"ໃບບິນ {o.order_id} · {int(o.amount or 0):,} ກີບ "
                            f"· ຊຳລະທັນກຳນົດ ບໍ່ມີດອກເບ້ຍ",
                    "created_at": _at(o.payment_due_date - timedelta(days=7)),
                    "action": "credit",
                })

    # ── ຄຳສັ່ງຊື້ເມັດກາເຟ ─────────────────────────────────────────────
    cutoff = lao_now() - timedelta(days=RECENT_ORDER_DAYS)
    orders = db.scalars(
        select(BeanOrder).where(
            BeanOrder.owner_id == owner.id,
            BeanOrder.created_at >= cutoff,
        ).order_by(BeanOrder.created_at.desc()).limit(20)
    ).all()

    for bo in orders:
        meta = {
            "delivered": ("success", "ຄຳສັ່ງຖືກສົ່ງແລ້ວ",
                          "ເມັດກາເຟຖືກເພີ່ມເຂົ້າສະຕັອກຂອງທ່ານແລ້ວ"),
            "processing": ("info", "ກຳລັງກຽມຄຳສັ່ງ",
                           "ທີມງານກຳລັງກຽມເຄື່ອງໃຫ້ທ່ານ"),
            "pending_payment": ("warning", "ລໍການຢືນຢັນການຊຳລະ",
                                "ພວກເຮົາກຳລັງກວດການໂອນຂອງທ່ານ"),
            "cancelled": ("danger", "ຄຳສັ່ງຖືກຍົກເລີກ", "ຄຳສັ່ງນີ້ຖືກຍົກເລີກແລ້ວ"),
        }.get(bo.status)
        if not meta:
            continue
        severity, title, body = meta
        items.append({
            "id": f"order:{bo.id}:{bo.status}",
            "type": "order",
            "severity": severity,
            "title": title,
            "body": f"{bo.product_name} {bo.quantity:g} {bo.unit or 'ກີໂລ'} "
                    f"· {int(bo.total_price or 0):,} ກີບ — {body}",
            "created_at": _at(bo.updated_at or bo.created_at),
            "action": "orders",
        })

    # ── ສະຕັອກເມັດກາເຟ ────────────────────────────────────────────────
    kg = float(owner.bean_balance_kg or 0)
    if kg <= LOW_STOCK_KG:
        items.append({
            "id": f"stock:{owner.id}:{'out' if kg <= 0 else 'low'}",
            "type": "stock",
            "severity": "danger" if kg <= 0 else "warning",
            "title": "ເມັດກາເຟໝົດແລ້ວ" if kg <= 0 else "ເມັດກາເຟໃກ້ໝົດ",
            "body": f"ຍັງເຫຼືອ {kg:g} ກີໂລ — ສັ່ງເພີ່ມກ່ອນຂາຍບໍ່ໄດ້",
            "created_at": _at(lao_now()),
            "action": "products",
        })

    items.sort(key=lambda x: x["created_at"], reverse=True)
    return items


@router.get("")
def list_notifications(db: Session = Depends(get_db),
                       owner: ShopOwner = Depends(_get_owner)):
    items = _build(db, owner)
    seen = owner.notifications_seen_at
    seen_iso = _at(seen) if seen else ""
    for it in items:
        it["unread"] = it["created_at"] > seen_iso
    db.commit()      # shop_for_owner ອາດຜູກ owner_id ໃຫ້
    return {
        "items": items,
        "unread_count": sum(1 for i in items if i["unread"]),
    }


@router.get("/unread-count")
def unread_count(db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    items = _build(db, owner)
    seen_iso = _at(owner.notifications_seen_at) if owner.notifications_seen_at else ""
    db.commit()
    return {"unread_count": sum(1 for i in items if i["created_at"] > seen_iso)}


@router.post("/seen")
def mark_seen(db: Session = Depends(get_db),
              owner: ShopOwner = Depends(_get_owner)):
    owner.notifications_seen_at = datetime.now(timezone.utc)
    db.commit()
    return {"unread_count": 0}
