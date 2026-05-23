from sqlalchemy import Column, Integer, String, Numeric, Boolean, DateTime, Text
from sqlalchemy.sql import func
from ..database import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    origin = Column(String(255), nullable=True)
    category = Column(String(50), nullable=False)
    price = Column(Integer, nullable=False)
    unit = Column(String(20), nullable=True)
    stock_qty = Column(Numeric, default=0)
    image_url = Column(Text, nullable=True)
    active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
