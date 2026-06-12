from sqlalchemy import Column, Integer, String, Float, Date, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from ..database import Base


class BeanOrder(Base):
    __tablename__ = "bean_orders_merchant"

    id           = Column(Integer, primary_key=True, index=True)
    owner_id     = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)
    product_id   = Column(Integer, nullable=False)
    product_name = Column(String(200), nullable=False)
    quantity     = Column(Float, nullable=False)
    unit         = Column(String(30), nullable=True)
    unit_price   = Column(Float, nullable=False)
    total_price  = Column(Float, nullable=False)
    status          = Column(String(50), default="processing", nullable=False)
    payment_method  = Column(String(20), nullable=True)
    phone           = Column(String(50), nullable=True)
    delivery_address= Column(String(500), nullable=True)
    delivery_date   = Column(Date, nullable=True)
    note            = Column(Text, nullable=True)
    delivered_at    = Column(DateTime(timezone=True), nullable=True)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    updated_at      = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
