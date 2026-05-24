from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from ..database import Base


class Prospect(Base):
    __tablename__ = "prospects"

    id = Column(Integer, primary_key=True, index=True)
    shop_name = Column(String(200), nullable=False)
    owner_name = Column(String(200), nullable=False)
    phone = Column(String(50), nullable=True)
    village = Column(String(200), nullable=True)
    district = Column(String(200), nullable=True)
    province = Column(String(200), nullable=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    daily_coffee_kg = Column(Float, default=0)
    weekly_coffee_kg = Column(Float, default=0)
    interest = Column(String(20), default="undecided")  # interested / not_interested / undecided
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    created_by_id = Column(Integer, ForeignKey("admins.id"), nullable=True)
