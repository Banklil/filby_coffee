from sqlalchemy import Column, Integer, String, BigInteger, Boolean, DateTime, Text
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
    credit_used = Column(BigInteger, default=0)
    tier = Column(String(20), default="bronze")
    status = Column(String(20), default="active")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    orders = relationship("Order", back_populates="shop")
    transactions = relationship("Transaction", back_populates="shop")
    applications = relationship("Application", back_populates="shop")
