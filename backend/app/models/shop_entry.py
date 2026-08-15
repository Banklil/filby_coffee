from sqlalchemy import (
    Column, Integer, String, BigInteger, DateTime, Text, Date, ForeignKey, Index,
)
from sqlalchemy.sql import func

from ..database import Base


class ShopEntry(Base):
    """ລາຍຮັບ-ລາຍຈ່າຍທີ່ຮ້ານບັນທຶກເອງ.

    ຄົນລະອັນກັບ FinanceEntry ຊຶ່ງເປັນບັນຊີຂອງບໍລິສັດ Filby (ຜູກກັບ admins).
    ອັນນີ້ຜູກກັບ shop_owners — ເປັນເງິນເຂົ້າ-ອອກພາຍໃນຮ້ານຂອງລູກຄ້າເອງ.

    ບໍ່ລວມ: ການຂາຍຜ່ານ POS ແລະ ການສັ່ງຊື້ເມັດກາເຟ — ສອງອັນນັ້ນນັບຈາກ
    pos_sales_merchant ແລະ bean_orders_merchant ຢູ່ແລ້ວ. ຖ້າບັນທຶກຊ້ຳຢູ່ນີ້
    ຕົວເລກຈະຖືກນັບສອງເທື່ອ.
    """

    __tablename__ = "shop_entries_merchant"

    id       = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)

    type     = Column(String(10), nullable=False)   # income | expense
    category = Column(String(60), nullable=False)
    amount   = Column(BigInteger, nullable=False)   # ກີບ
    note     = Column(Text, nullable=True)

    entry_date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(),
                        onupdate=func.now())

    __table_args__ = (
        Index("ix_shop_entry_owner_date", "owner_id", "entry_date"),
    )
