from sqlalchemy import Column, Integer, String, BigInteger, DateTime, Text, Date, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String(20), unique=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=False)
    amount = Column(BigInteger, nullable=False)
    items = Column(JSONB, nullable=False)
    shipping_address = Column(Text, nullable=True)
    status = Column(String(20), default="pending")
    payment_method = Column(String(20), nullable=True)
    tracking_number = Column(String(100), nullable=True)
    payment_due_date = Column(Date, nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    shop = relationship("Shop", back_populates="orders")
    transactions = relationship("Transaction", back_populates="related_order")
