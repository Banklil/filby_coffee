from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from ..database import Base


class CreditApplication(Base):
    __tablename__ = "credit_applications_merchant"

    id             = Column(Integer, primary_key=True, index=True)
    owner_id       = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)
    full_name      = Column(String(200), nullable=False)
    phone          = Column(String(20), nullable=False)
    id_card        = Column(String(50), nullable=False)
    business_name  = Column(String(200), nullable=True)
    amount         = Column(Float, nullable=False)
    purpose        = Column(Text, nullable=False)
    monthly_income = Column(Float, nullable=True)
    status         = Column(String(50), default="pending", nullable=False, index=True)
    approved_limit = Column(Float, nullable=True)
    reviewer_note  = Column(Text, nullable=True)
    reviewed_at    = Column(DateTime(timezone=True), nullable=True)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
