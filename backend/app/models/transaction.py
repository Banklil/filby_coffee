from sqlalchemy import Column, Integer, String, BigInteger, DateTime, Text, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=False)
    type = Column(String(20), nullable=False)
    amount = Column(BigInteger, nullable=False)
    related_order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    shop = relationship("Shop", back_populates="transactions")
    related_order = relationship("Order", back_populates="transactions")
