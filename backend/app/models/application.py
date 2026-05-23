from sqlalchemy import Column, Integer, String, BigInteger, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class Application(Base):
    __tablename__ = "applications"

    id = Column(Integer, primary_key=True, index=True)
    ref_id = Column(String(20), unique=True, index=True)
    shop_data = Column(JSONB, nullable=False)
    credit_requested = Column(BigInteger, nullable=False)
    purpose = Column(String(50), nullable=True)
    status = Column(String(20), default="pending")
    reviewed_by = Column(Integer, ForeignKey("admins.id"), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    review_notes = Column(Text, nullable=True)
    approved_limit = Column(BigInteger, nullable=True)
    shop_id = Column(Integer, ForeignKey("shops.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    reviewer = relationship("Admin", foreign_keys=[reviewed_by])
    shop = relationship("Shop", back_populates="applications")
