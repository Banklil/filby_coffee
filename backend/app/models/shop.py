from sqlalchemy import Column, Integer, String, BigInteger, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class Shop(Base):
    __tablename__ = "shops"

    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(String(20), unique=True, index=True)
    name = Column(String(255), nullable=False)
    owner_name = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=False)
    email = Column(String(255), nullable=True)
    province = Column(String(100), nullable=False)
    district = Column(String(100), nullable=True)
    village = Column(String(100), nullable=True)
    address_detail = Column(Text, nullable=True)
    years_in_biz = Column(String(20), nullable=True)
    revenue_range = Column(String(20), nullable=True)
    shop_types = Column(JSONB, nullable=True)
    staff_count = Column(String(20), nullable=True)
    credit_limit = Column(BigInteger, default=0)
    # Cache only — the truth is SUM(credit_ledger.signed_amount). Kept so the
    # existing dashboard/analytics queries keep working; refreshed on every
    # credit movement and re-checked by the daily job.
    credit_used = Column(BigInteger, default=0)
    tier = Column(String(20), default="bronze")
    status = Column(String(20), default="active")

    # ── ສິນເຊື່ອ ──────────────────────────────────────────────────────
    # ຜູກກັບບັນຊີຜູ້ໃຊ້ໂດຍກົງ ແທນການຈັບຄູ່ດ້ວຍ email ທີ່ສ້າງຮ້ານຊ້ຳໄດ້
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=True, index=True)

    # ເງິນມັດຈຳທີ່ຖືໄວ້ເປັນຫຼັກປະກັນ — ຖອນບໍ່ໄດ້ຂະນະຍັງມີໜີ້
    deposit_balance = Column(BigInteger, default=0, nullable=False, server_default="0")

    # good | watch | on_hold | suspended | defaulted
    credit_status = Column(String(16), default="good", nullable=False, server_default="good")

    # ມື້ປອດດອກເບ້ຍ ນັບຈາກວັນສົ່ງເຄື່ອງ
    net_terms_days = Column(Integer, default=30, nullable=False, server_default="30")

    # ວົງເງິນທີ່ໃຫ້ໄດ້ໂດຍບໍ່ຕ້ອງມີມັດຈຳ (ໃຫ້ຕາມປະຫວັດການຈ່າຍ)
    unsecured_allowance = Column(BigInteger, default=0, nullable=False, server_default="0")

    # ຕົວຄູນມັດຈຳ: 2 = ມັດຈຳ 50% ຂອງວົງເງິນ, 4 = ມັດຈຳ 25%
    deposit_multiplier = Column(Integer, default=2, nullable=False, server_default="2")

    last_review_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    orders = relationship("Order", back_populates="shop")
    transactions = relationship("Transaction", back_populates="shop")
    applications = relationship("Application", back_populates="shop")
