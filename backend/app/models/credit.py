"""ຕາຕະລາງສິນເຊື່ອ — ledger, ການຈອງວົງເງິນ, ແລະ ເງິນມັດຈຳ.

ຫຼັກການ: ຍອດໜີ້ບໍ່ໄດ້ເກັບເປັນຕົວເລກທີ່ແກ້ໄດ້ ແຕ່ຄິດຈາກຜົນລວມຂອງ ledger ສະເໝີ.
Shop.credit_used ຍັງມີຢູ່ ແຕ່ເປັນພຽງ cache ໃຫ້ dashboard ເກົ່າອ່ານ.
"""
from sqlalchemy import (
    Column, Integer, BigInteger, String, Text, DateTime,
    ForeignKey, Index, CheckConstraint, UniqueConstraint,
)
from sqlalchemy.sql import func
from ..database import Base


class CreditLedger(Base):
    """Append-only. ຫ້າມ UPDATE ຫ້າມ DELETE — ແກ້ຜິດດ້ວຍການຂຽນແຖວກົງກັນຂ້າມ."""

    __tablename__ = "credit_ledger"

    id      = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=False, index=True)

    # ບວກ = ໜີ້ເພີ່ມ, ລົບ = ໜີ້ຫຼຸດ.  ຍອດໜີ້ = SUM(signed_amount)
    signed_amount = Column(BigInteger, nullable=False)

    # ໜີ້ເພີ່ມ : order_capture | interest | adjust_debit
    # ໜີ້ຫຼຸດ  : payment | refund | credit_note | deposit_applied | write_off
    entry_type = Column(String(24), nullable=False, index=True)

    order_id    = Column(Integer, ForeignKey("orders.id"), nullable=True, index=True)
    description = Column(Text, nullable=True)
    created_by  = Column(Integer, ForeignKey("admins.id"), nullable=True)

    # ກັນການບັນທຶກຊ້ຳຈາກການກົດສອງເທື່ອ ຫຼື job ທີ່ແລ່ນຄືນ
    idempotency_key = Column(String(120), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    __table_args__ = (
        UniqueConstraint("idempotency_key", name="uq_credit_ledger_idem"),
        Index("ix_credit_ledger_shop_created", "shop_id", "created_at"),
    )


class CreditHold(Base):
    """ວົງເງິນທີ່ຈອງໄວ້ຕອນສັ່ງ ແຕ່ຍັງບໍ່ທັນເປັນໜີ້ (ຍັງບໍ່ໄດ້ສົ່ງເຄື່ອງ)."""

    __tablename__ = "credit_holds"

    id       = Column(Integer, primary_key=True, index=True)
    shop_id  = Column(Integer, ForeignKey("shops.id"), nullable=False, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True, index=True)
    amount   = Column(BigInteger, nullable=False)

    # active | captured | released | expired
    status = Column(String(16), nullable=False, default="active", index=True)

    expires_at  = Column(DateTime(timezone=True), nullable=False)
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    idempotency_key = Column(String(120), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        CheckConstraint("amount > 0", name="ck_credit_hold_positive"),
        UniqueConstraint("idempotency_key", name="uq_credit_hold_idem"),
        Index("ix_credit_hold_shop_status", "shop_id", "status"),
    )


class DepositMovement(Base):
    """ການເຄື່ອນໄຫວຂອງເງິນມັດຈຳ — ແຍກຈາກ ledger ໜີ້ຢ່າງເດັດຂາດ.

    ມັດຈຳເປັນເງິນຂອງຮ້ານທີ່ບໍລິສັດຖືໄວ້ເປັນຫຼັກປະກັນ ບໍ່ແມ່ນລາຍຮັບ
    ແລະ ບໍ່ນຳໄປຫັກໜີ້ໃນການຊຳລະປົກກະຕິ.
    """

    __tablename__ = "deposit_movements"

    id      = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=False, index=True)

    # + ຮັບເຂົ້າ, − ຄືນໃຫ້ຮ້ານ ຫຼື ຫັກລົບໜີ້
    signed_amount = Column(BigInteger, nullable=False)

    # received | refunded | applied_to_debt | forfeited
    movement_type = Column(String(24), nullable=False)

    reason      = Column(Text, nullable=True)
    approved_by = Column(Integer, ForeignKey("admins.id"), nullable=True)

    idempotency_key = Column(String(120), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("idempotency_key", name="uq_deposit_movement_idem"),
    )
