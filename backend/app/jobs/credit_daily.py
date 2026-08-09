"""Job ປະຈຳວັນຂອງລະບົບສິນເຊື່ອ.

ສາມໜ້າທີ່:
  1. ຄືນວົງເງິນທີ່ຈອງໄວ້ແຕ່ບໍ່ໄດ້ສົ່ງເຄື່ອງພາຍໃນກຳນົດ
  2. ຄິດດອກເບ້ຍລາຍວັນຂອງໃບບິນທີ່ພົ້ນ 30 ມື້ແລ້ວ ແລ້ວຂຽນລົງ ledger
  3. ປັບສະຖານະສິນເຊື່ອຂອງແຕ່ລະຮ້ານຕາມຈຳນວນມື້ທີ່ຊ້າສຸດ

ຕ້ອງແລ່ນວັນລະຄັ້ງ. ແລ່ນຊ້ຳໃນມື້ດຽວກັນບໍ່ເປັນຫຍັງ — idempotency_key
ຂອງແຕ່ລະລາຍການຜູກກັບວັນທີ ຈຶ່ງບໍ່ຄິດດອກຊ້ຳ.
"""
from datetime import timedelta

from sqlalchemy import select, func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..core import credit
from ..core.timeutil import lao_now
from ..models.audit_log import AuditLog
from ..models.credit import CreditHold, CreditLedger
from ..models.order import Order
from ..models.shop import Shop


def run_daily(db: Session) -> dict:
    today = lao_now().date()
    now = lao_now()
    stats = {"holds_expired": 0, "interest_entries": 0,
             "interest_total": 0, "status_changes": 0, "deposits_applied": 0}

    # ── 1. ຄືນວົງເງິນທີ່ຈອງໄວ້ຈົນໝົດອາຍຸ ─────────────────────────────
    for hold in db.scalars(select(CreditHold).where(
            CreditHold.status == "active",
            CreditHold.expires_at < now)):
        hold.status = "expired"
        hold.resolved_at = now
        stats["holds_expired"] += 1

    # ── 2. ຄິດດອກເບ້ຍລາຍວັນ ─────────────────────────────────────────
    # ຄິດຈາກຍອດຕົ້ນຂອງໃບບິນ ບໍ່ແມ່ນຍອດລວມທີ່ມີດອກສະສົມຢູ່ນຳ ເພື່ອໃຫ້
    # ຕົງກັບສູດທີ່ບອກລູກຄ້າໄວ້: ຍອດຄ້າງ × 0.1% × ຈຳນວນມື້ທີ່ຊ້າ
    overdue = db.scalars(select(Order).where(
        Order.paid_at.is_(None),
        Order.payment_due_date.isnot(None),
        Order.payment_due_date < today,
        Order.status == "delivered",
    )).all()

    for o in overdue:
        principal = int(o.amount or 0)
        fee = int(round(principal * credit.DAILY_RATE))
        if fee <= 0:
            continue
        late_days = (today - o.payment_due_date).days
        entry = CreditLedger(
            shop_id=o.shop_id,
            signed_amount=fee,
            entry_type="interest",
            order_id=o.id,
            description=f"ດອກເບ້ຍຊັກຊ້າ {o.order_id} — ມື້ທີ {late_days}",
            idempotency_key=f"interest:{o.id}:{today.isoformat()}",
        )
        db.add(entry)
        try:
            db.flush()                      # ຖ້າຄິດໄປແລ້ວມື້ນີ້ຈະຕິດ unique
        except IntegrityError:
            db.rollback()
            continue
        stats["interest_entries"] += 1
        stats["interest_total"] += fee

    # ── 3. ປັບສະຖານະຕາມມື້ທີ່ຊ້າສຸດ ──────────────────────────────────
    for shop in db.scalars(select(Shop).where(Shop.status == "active")):
        oldest_due = db.scalar(select(func.min(Order.payment_due_date)).where(
            Order.shop_id == shop.id,
            Order.paid_at.is_(None),
            Order.payment_due_date.isnot(None),
            Order.status == "delivered",
        ))

        late_days = (today - oldest_due).days if oldest_due and oldest_due < today else 0

        new_status = "good"
        for threshold, status in credit.STATUS_LADDER:
            if late_days >= threshold:
                new_status = status
                break

        if new_status != (shop.credit_status or "good"):
            db.add(AuditLog(
                admin_id=None, action="credit.status_change",
                entity_type="shop", entity_id=shop.id,
                log_metadata={"from": shop.credit_status, "to": new_status,
                              "late_days": late_days},
            ))
            shop.credit_status = new_status
            stats["status_changes"] += 1

        # ລະງັບແລ້ວ → ຄືນວົງເງິນທີ່ຈອງໄວ້ທັງໝົດ ຢຸດການສົ່ງເຄື່ອງ
        if new_status in ("suspended", "defaulted"):
            for hold in db.scalars(select(CreditHold).where(
                    CreditHold.shop_id == shop.id,
                    CreditHold.status == "active")):
                credit.release(db, hold, reason=f"ບັນຊີ {new_status}")

        # ຜິດນັດຊຳລະ → ຫັກມັດຈຳມາລ້າງໜີ້
        if new_status == "defaulted":
            taken = credit.apply_deposit_to_debt(
                db, shop.id, admin_id=None,
                reason=f"ຄ້າງຊຳລະ {late_days} ມື້",
            )
            if taken:
                stats["deposits_applied"] += taken

        credit._refresh_cache(db, shop)

    db.commit()
    return stats
