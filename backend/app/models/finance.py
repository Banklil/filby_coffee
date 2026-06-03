from sqlalchemy import Column, Integer, String, BigInteger, DateTime, Text, ForeignKey, Date
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..database import Base


class FinanceEntry(Base):
    __tablename__ = "finance_entries"

    id = Column(Integer, primary_key=True, index=True)
    type = Column(String(20), nullable=False)       # income | expense | capital
    category = Column(String(100), nullable=False)
    amount = Column(BigInteger, nullable=False)      # ກີບ
    description = Column(Text, nullable=True)
    reference = Column(String(200), nullable=True)  # ເລກບິນ / ໃບຮັບເງິນ
    entry_date = Column(Date, nullable=False)
    created_by = Column(Integer, ForeignKey("admins.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    created_by_admin = relationship("Admin", foreign_keys=[created_by])
