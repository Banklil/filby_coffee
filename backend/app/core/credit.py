"""ບໍລິການສິນເຊື່ອ — ບ່ອນດຽວທີ່ໄດ້ຮັບອະນຸຍາດໃຫ້ຂະຫຍັບຕົວເລກໜີ້.

Router ທຸກອັນຕ້ອງເອີ້ນຜ່ານໄຟລ໌ນີ້ ຫ້າມແກ້ Shop.credit_used ໂດຍກົງ.

ນະໂຍບາຍຕ້ອງຕົງກັບ lib/widgets/credit_terms.dart ໃນແອັບ:
  ປອດດອກເບ້ຍ 30 ມື້ ນັບຈາກວັນສົ່ງເຄື່ອງ → ຫຼັງຈາກນັ້ນ 3%/ເດືອນ ຄິດເປັນລາຍມື້.
"""
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, func
from sqlalchemy.orm import Session

from ..models.shop import Shop
from ..models.credit import CreditLedger, CreditHold, DepositMovement

# ── ນະໂຍບາຍ ──────────────────────────────────────────────────────────
GRACE_DAYS = 30          # ມື້ປອດດອກເບ້ຍ ນັບຈາກວັນສົ່ງເຄື່ອງ
MONTHLY_RATE = 0.03      # ດອກເບ້ຍຫຼັງພົ້ນກຳນົດ
DAILY_RATE = MONTHLY_RATE / 30     # 0.001 = 0.1% ຕໍ່ມື້

BLOCK_AFTER_DAYS = 15    # ຊ້າເທົ່ານີ້ → ສັ່ງເຄື່ອງໃໝ່ບໍ່ໄດ້
SUSPEND_AFTER_DAYS = 45  # ຊ້າເທົ່ານີ້ → ລະງັບບັນຊີ
DEFAULT_AFTER_DAYS = 60  # ຊ້າເທົ່ານີ້ → ຜິດນັດຊຳລະ, ຫັກມັດຈຳ

HOLD_TTL_DAYS = 14       # ຈອງວົງເງິນໄວ້ໄດ້ດົນເທົ່າໃດກ່ອນຄືນອັດຕະໂນມັດ

BLOCKED_STATUSES = {"on_hold", "suspended", "defaulted"}

# ຈຳນວນມື້ຊ້າ → ສະຖານະ (ຮຽງຈາກໜັກໄປເບົາ, ອັນທຳອິດທີ່ຕົງຄືຄຳຕອບ)
STATUS_LADDER = [
    (DEFAULT_AFTER_DAYS, "defaulted"),
    (SUSPEND_AFTER_DAYS, "suspended"),
    (BLOCK_AFTER_DAYS, "on_hold"),
    (1, "watch"),
]


# ── ຂໍ້ຜິດພາດ ─────────────────────────────────────────────────────────
class CreditError(Exception):
    """Router ປ່ຽນເປັນ 4xx — ບໍ່ໃຫ້ກາຍເປັນ 500."""


class CreditBlocked(CreditError):
    def __init__(self, status: str):
        self.status = status
        super().__init__(f"credit blocked: {status}")


class CreditLimitExceeded(CreditError):
    def __init__(self, requested: int, available: int):
        self.requested = requested
        self.available = available
        super().__init__(f"requested {requested} > available {available}")


# ── ການຄິດໄລ່ ─────────────────────────────────────────────────────────
def balance(db: Session, shop_id: int) -> int:
    """ໜີ້ຈິງທີ່ຕັດແລ້ວ — ຄິດຈາກ ledger ສະເໝີ."""
    return int(db.scalar(
        select(func.coalesce(func.sum(CreditLedger.signed_amount), 0))
        .where(CreditLedger.shop_id == shop_id)
    ) or 0)


def active_holds(db: Session, shop_id: int) -> int:
    return int(db.scalar(
        select(func.coalesce(func.sum(CreditHold.amount), 0))
        .where(CreditHold.shop_id == shop_id, CreditHold.status == "active")
    ) or 0)


def effective_limit(shop: Shop) -> int:
    """ມັດຈຳເປັນເພດານ — ບໍ່ວ່າຝ່າຍບໍລິຫານຈະອະນຸມັດເທົ່າໃດກໍ່ຕາມ.

    ຄວາມສູນເສຍສູງສຸດຖ້າຮ້ານໜີ = effective_limit − deposit_balance
    """
    secured = (shop.unsecured_allowance or 0) + \
              (shop.deposit_balance or 0) * (shop.deposit_multiplier or 0)
    return max(0, min(int(shop.credit_limit or 0), int(secured)))


def available(db: Session, shop: Shop) -> int:
    return max(0, effective_limit(shop)
                  - balance(db, shop.id)
                  - active_holds(db, shop.id))


def required_deposit(shop: Shop) -> int:
    """ມັດຈຳທີ່ຍັງຕ້ອງວາງເພີ່ມ ເພື່ອປົດວົງເງິນທີ່ອະນຸມັດໄວ້ໃຫ້ຄົບ.

    ຝ່າຍບໍລິຫານອະນຸມັດວົງເງິນໄດ້ ແຕ່ວົງເງິນນັ້ນຈະໃຊ້ບໍ່ໄດ້ຈົນກວ່າມັດຈຳຈະພໍ.
    ຖ້າບໍ່ບອກຈຳນວນນີ້ ຮ້ານຈະເຫັນວົງເງິນໃຫຍ່ໆ ແຕ່ສັ່ງເຄື່ອງບໍ່ໄດ້ ໂດຍບໍ່ຮູ້ສາເຫດ.
    """
    approved = int(shop.credit_limit or 0)
    unsecured = int(shop.unsecured_allowance or 0)
    mult = int(shop.deposit_multiplier or 0)
    if approved <= 0 or mult <= 0:
        return 0
    gap = approved - unsecured
    if gap <= 0:
        return 0
    needed = -(-gap // mult)          # ປັດຂຶ້ນ
    return max(0, needed - int(shop.deposit_balance or 0))


def snapshot(db: Session, shop: Shop) -> dict:
    """ຂໍ້ມູນສິນເຊື່ອສຳລັບສະແດງໃນແອັບ ແລະ dashboard."""
    bal = balance(db, shop.id)
    holds = active_holds(db, shop.id)
    lim = effective_limit(shop)
    deposit = int(shop.deposit_balance or 0)
    approved = int(shop.credit_limit or 0)
    return {
        "approved_limit":  approved,
        "effective_limit": lim,
        "balance":         bal,
        "held":            holds,
        "available":       max(0, lim - bal - holds),
        "deposit":         deposit,
        "net_exposure":    bal + holds - deposit,
        "credit_status":   shop.credit_status or "good",
        "grace_days":      GRACE_DAYS,
        "monthly_rate":    MONTHLY_RATE,
        # ອະນຸມັດແລ້ວ ແຕ່ຍັງໃຊ້ບໍ່ໄດ້ເພາະມັດຈຳຍັງບໍ່ພໍ
        "deposit_multiplier": int(shop.deposit_multiplier or 0),
        "required_deposit":   required_deposit(shop),
        "awaiting_deposit":   approved > 0 and lim <= 0,
    }


# ── ການເຄື່ອນໄຫວ ──────────────────────────────────────────────────────
def reserve(db: Session, shop_id: int, amount: int, *, idem: str) -> CreditHold:
    """ຈອງວົງເງິນ. ຕ້ອງເອີ້ນກ່ອນສ້າງ order ສະເໝີ.

    ລັອກແຖວຮ້ານໄວ້ ເພື່ອບໍ່ໃຫ້ສອງຄຳສັ່ງທີ່ມາພ້ອມກັນຜ່ານການກວດທັງສອງ.
    """
    amount = int(amount)
    if amount <= 0:
        raise CreditError("ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ 0")

    existing = db.scalar(select(CreditHold).where(CreditHold.idempotency_key == idem))
    if existing:
        return existing  # ກົດຊ້ຳ — ຄືນອັນເກົ່າ ບໍ່ຈອງເພີ່ມ

    shop = db.execute(
        select(Shop).where(Shop.id == shop_id).with_for_update()
    ).scalar_one()

    if (shop.credit_status or "good") in BLOCKED_STATUSES:
        raise CreditBlocked(shop.credit_status)

    avail = available(db, shop)
    if amount > avail:
        raise CreditLimitExceeded(requested=amount, available=avail)

    hold = CreditHold(
        shop_id=shop.id,
        amount=amount,
        status="active",
        expires_at=datetime.now(timezone.utc) + timedelta(days=HOLD_TTL_DAYS),
        idempotency_key=idem,
    )
    db.add(hold)
    db.flush()
    return hold


def capture(db: Session, hold: CreditHold, order, *, admin_id: int | None = None) -> None:
    """ສົ່ງເຄື່ອງສຳເລັດ → ການຈອງກາຍເປັນໜີ້ຈິງ ແລະ ເລີ່ມນັບ 30 ມື້."""
    if hold.status != "active":
        return  # ຕັດໄປແລ້ວ ຫຼື ຄືນໄປແລ້ວ — ບໍ່ເຮັດຫຍັງຊ້ຳ

    shop = db.execute(
        select(Shop).where(Shop.id == hold.shop_id).with_for_update()
    ).scalar_one()

    db.add(CreditLedger(
        shop_id=shop.id,
        signed_amount=int(hold.amount),
        entry_type="order_capture",
        order_id=order.id,
        description=f"ສົ່ງເຄື່ອງ {order.order_id}",
        created_by=admin_id,
        idempotency_key=f"capture:hold:{hold.id}",
    ))

    hold.status = "captured"
    hold.order_id = order.id
    hold.resolved_at = datetime.now(timezone.utc)

    # ນີ້ຄືຈຸດທີ່ນາຬິກາ 30 ມື້ເລີ່ມເດີນ
    order.payment_due_date = (
        datetime.now(timezone.utc).date()
        + timedelta(days=int(shop.net_terms_days or GRACE_DAYS))
    )
    _refresh_cache(db, shop)


def capture_for_order(db: Session, order, *, admin_id: int | None = None) -> bool:
    """ຫາການຈອງຂອງ order ນີ້ແລ້ວຕັດເປັນໜີ້. ຄືນ True ຖ້າຕັດແລ້ວ."""
    hold = db.scalar(
        select(CreditHold).where(
            CreditHold.order_id == order.id,
            CreditHold.status == "active",
        )
    )
    if not hold:
        return False
    capture(db, hold, order, admin_id=admin_id)
    return True


def release(db: Session, hold: CreditHold, reason: str = "ຍົກເລີກ") -> None:
    """ຍົກເລີກ ຫຼື ໝົດອາຍຸ → ຄືນວົງເງິນ ໂດຍບໍ່ແຕະ ledger."""
    if hold.status != "active":
        return
    hold.status = "released"
    hold.resolved_at = datetime.now(timezone.utc)


def release_for_order(db: Session, order_id: int, reason: str = "ຍົກເລີກ") -> None:
    for hold in db.scalars(
        select(CreditHold).where(
            CreditHold.order_id == order_id,
            CreditHold.status == "active",
        )
    ):
        release(db, hold, reason)


def post_payment(db: Session, shop_id: int, amount: int, *,
                 admin_id: int | None, idem: str, note: str = "") -> int:
    """ຮັບຊຳລະ. ຂຽນ CREDIT ລົງ ledger ແລ້ວປິດ order ເກົ່າສຸດກ່ອນ (FIFO).

    ຄືນຈຳນວນເງິນທີ່ຍັງຈັບຄູ່ກັບ order ບໍ່ໄດ້ (ເງິນລ່ວງໜ້າ).
    """
    from ..models.order import Order

    amount = int(amount)
    if amount <= 0:
        raise CreditError("ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ 0")

    if db.scalar(select(CreditLedger).where(CreditLedger.idempotency_key == idem)):
        return 0  # ບັນທຶກໄປແລ້ວ

    shop = db.execute(
        select(Shop).where(Shop.id == shop_id).with_for_update()
    ).scalar_one()

    db.add(CreditLedger(
        shop_id=shop.id,
        signed_amount=-amount,
        entry_type="payment",
        description=note or "ຮັບຊຳລະສິນເຊື່ອ",
        created_by=admin_id,
        idempotency_key=idem,
    ))

    # ປິດ order ເກົ່າສຸດກ່ອນ ເພື່ອໃຫ້ອາຍຸໜີ້ ແລະ ການຄິດດອກຖືກຕ້ອງ
    remaining = amount
    unpaid = db.scalars(
        select(Order)
        .where(
            Order.shop_id == shop.id,
            Order.paid_at.is_(None),
            Order.payment_due_date.isnot(None),
        )
        .order_by(Order.payment_due_date)
    ).all()

    for o in unpaid:
        if remaining < int(o.amount or 0):
            break
        o.paid_at = datetime.now(timezone.utc)
        remaining -= int(o.amount or 0)

    _refresh_cache(db, shop)
    return remaining


def add_deposit(db: Session, shop_id: int, amount: int, *,
                admin_id: int | None, idem: str, reason: str = "ຮັບເງິນມັດຈຳ") -> int:
    """ຮັບເງິນມັດຈຳ. ບໍ່ແຕະ ledger ໜີ້ — ນີ້ບໍ່ແມ່ນການຊຳລະ."""
    amount = int(amount)
    if amount <= 0:
        raise CreditError("ຈຳນວນເງິນຕ້ອງຫຼາຍກວ່າ 0")

    if db.scalar(select(DepositMovement).where(DepositMovement.idempotency_key == idem)):
        return 0

    shop = db.execute(
        select(Shop).where(Shop.id == shop_id).with_for_update()
    ).scalar_one()

    db.add(DepositMovement(
        shop_id=shop.id, signed_amount=amount, movement_type="received",
        reason=reason, approved_by=admin_id, idempotency_key=idem,
    ))
    shop.deposit_balance = int(shop.deposit_balance or 0) + amount
    return int(shop.deposit_balance)


def refund_deposit(db: Session, shop_id: int, *,
                   admin_id: int | None, idem: str, reason: str = "ປິດບັນຊີສິນເຊື່ອ") -> int:
    """ຄືນມັດຈຳ — ອະນຸຍາດສະເພາະເມື່ອບໍ່ມີໜີ້ ແລະ ບໍ່ມີການຈອງຄ້າງ."""
    shop = db.execute(
        select(Shop).where(Shop.id == shop_id).with_for_update()
    ).scalar_one()

    owed = balance(db, shop.id)
    held = active_holds(db, shop.id)
    if owed > 0 or held > 0:
        raise CreditError(
            f"ຍັງມີໜີ້ຄ້າງ {owed:,} ກີບ ແລະ ວົງເງິນຈອງ {held:,} ກີບ — ຄືນມັດຈຳບໍ່ໄດ້"
        )

    amount = int(shop.deposit_balance or 0)
    if amount <= 0:
        return 0
    if db.scalar(select(DepositMovement).where(DepositMovement.idempotency_key == idem)):
        return 0

    db.add(DepositMovement(
        shop_id=shop.id, signed_amount=-amount, movement_type="refunded",
        reason=reason, approved_by=admin_id, idempotency_key=idem,
    ))
    shop.deposit_balance = 0
    return amount


def apply_deposit_to_debt(db: Session, shop_id: int, *,
                          admin_id: int | None, reason: str) -> int:
    """ໃຊ້ສະເພາະຕອນຜິດນັດຊຳລະ. ຫັກມັດຈຳມາລ້າງໜີ້."""
    shop = db.execute(
        select(Shop).where(Shop.id == shop_id).with_for_update()
    ).scalar_one()

    owed = balance(db, shop.id)
    take = min(int(shop.deposit_balance or 0), max(0, owed))
    if take <= 0:
        return 0

    today = datetime.now(timezone.utc).date().isoformat()
    if db.scalar(select(DepositMovement).where(
            DepositMovement.idempotency_key == f"dep-apply:{shop.id}:{today}")):
        return 0

    db.add(DepositMovement(
        shop_id=shop.id, signed_amount=-take, movement_type="applied_to_debt",
        reason=reason, approved_by=admin_id,
        idempotency_key=f"dep-apply:{shop.id}:{today}",
    ))
    db.add(CreditLedger(
        shop_id=shop.id, signed_amount=-take, entry_type="deposit_applied",
        description=f"ຫັກມັດຈຳ: {reason}", created_by=admin_id,
        idempotency_key=f"dep-ledger:{shop.id}:{today}",
    ))

    shop.deposit_balance = int(shop.deposit_balance or 0) - take
    _refresh_cache(db, shop)
    return take


def _refresh_cache(db: Session, shop: Shop) -> None:
    """ອັບເດດ Shop.credit_used ໃຫ້ dashboard ເກົ່າຍັງອ່ານໄດ້ຖືກຕ້ອງ."""
    db.flush()
    shop.credit_used = max(0, balance(db, shop.id))


# ── ຜູກຮ້ານກັບບັນຊີຜູ້ໃຊ້ ────────────────────────────────────────────
def shop_for_owner(db: Session, owner, *, create: bool = True) -> Shop | None:
    """ຫາຮ້ານຂອງ owner ດ້ວຍ FK ກ່ອນ ຄ່ອຍຖອຍໄປໃຊ້ email.

    ການຈັບຄູ່ດ້ວຍ email ຢ່າງດຽວເຄີຍສ້າງຮ້ານຊ້ຳ ເຮັດໃຫ້ວົງເງິນທີ່ອະນຸມັດ
    ຕິດຢູ່ຮ້ານໜຶ່ງ ແຕ່ຄຳສັ່ງຊື້ໄປຢູ່ອີກຮ້ານໜຶ່ງ. ພົບເມື່ອໃດກໍ່ຜູກ FK ໃຫ້ເລີຍ.
    """
    shop = db.scalar(select(Shop).where(Shop.owner_id == owner.id))
    if shop:
        return shop

    if owner.email:
        shop = db.scalar(select(Shop).where(func.lower(Shop.email) == owner.email.lower()))
        if shop:
            shop.owner_id = owner.id      # ຜູກໄວ້ ຈະບໍ່ຕ້ອງເດົາອີກ
            db.flush()
            return shop

    if not create:
        return None

    count = int(db.scalar(select(func.count(Shop.id))) or 0)
    shop = Shop(
        shop_id=f"FC{count + 1:04d}",
        name=owner.shop_name or owner.email,
        owner_name=owner.shop_name or owner.email,
        phone=owner.phone or "—",
        email=owner.email,
        province="ວຽງຈັນ",
        status="active",
        tier="bronze",
        credit_limit=0,
        credit_used=0,
        owner_id=owner.id,
    )
    db.add(shop)
    db.flush()
    return shop
