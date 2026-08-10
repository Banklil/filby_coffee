from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, LargeBinary
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class ShopOwner(Base):
    __tablename__ = "shop_owners"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    shop_name = Column(String(255), default="ຮ້ານຂອງຂ້ອຍ")
    phone     = Column(String(30), nullable=True)
    address   = Column(String(500), nullable=True)
    active    = Column(Boolean, default=True)
    # Remaining coffee-bean stock for this shop, in kilograms.
    bean_balance_kg = Column(Float, default=0, nullable=False, server_default="0")
    # ເວລາທີ່ເປີດເບິ່ງການເຕືອນຄັ້ງສຸດທ້າຍ — ອັນທີ່ໃໝ່ກວ່ານີ້ຖືວ່າຍັງບໍ່ໄດ້ອ່ານ
    notifications_seen_at = Column(DateTime(timezone=True), nullable=True)
    # ໂລໂກ້ຮ້ານ — ເກັບ bytes ໄວ້ນີ້ ບໍ່ແມ່ນໃນ disk ທີ່ຫາຍຕອນ redeploy
    logo_data = Column(LargeBinary, nullable=True)
    logo_mime = Column(String(40), nullable=True)
    logo_updated_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
