from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from ..database import Base


class PosSale(Base):
    """A single POS checkout ("ຮັບເງິນ") made by a shop from the mobile POS.
    Used to power the shop's income reports and best-seller stats."""
    __tablename__ = "pos_sales_merchant"

    id         = Column(Integer, primary_key=True, index=True)
    owner_id   = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)
    amount     = Column(Float, nullable=False, default=0)   # total sale in kip
    beans_kg   = Column(Float, nullable=False, default=0)   # beans consumed by this sale
    items      = Column(JSONB, nullable=True)               # [{name, qty, price}]
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
