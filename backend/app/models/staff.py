"""ພະນັກງານ, ການລົງເວລາ ແລະ ເງິນເດືອນ.

ພະນັກງານມີບັນຊີຂອງຕົນເອງ (ເບີໂທ + PIN) ແຕ່ເຫັນໄດ້ພຽງສອງຢ່າງ:
ກົດເຂົ້າ-ອອກວຽກ ແລະ ເບິ່ງເງິນເດືອນຂອງຕົນ. ບໍ່ເຫັນຍອດຂາຍ, ບໍ່ເຫັນສິນເຊື່ອ,
ບໍ່ເຫັນຂໍ້ມູນພະນັກງານຄົນອື່ນ.
"""
from sqlalchemy import (
    Column, Integer, String, BigInteger, Float, Boolean, Date, DateTime,
    Text, ForeignKey, Index, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func

from ..database import Base


class Staff(Base):
    __tablename__ = "staff_merchant"

    id       = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)

    name  = Column(String(120), nullable=False)
    phone = Column(String(30), nullable=False)      # ໃຊ້ເປັນ username
    pin_hash = Column(String(255), nullable=False)  # bcrypt ຄືກັບລະຫັດຜ່ານ
    role  = Column(String(60), nullable=True)       # ບາຣິສຕ້າ, ແຄັດເຊຍ...

    # monthly = ເງິນເດືອນຄົງທີ່ · hourly = ຈ່າຍຕາມຊົ່ວໂມງ
    pay_type    = Column(String(10), nullable=False, default="monthly")
    base_salary = Column(BigInteger, nullable=False, default=0)   # ກີບ/ເດືອນ
    hourly_rate = Column(BigInteger, nullable=False, default=0)   # ກີບ/ຊົ່ວໂມງ

    active     = Column(Boolean, nullable=False, default=True, server_default="true")
    started_on = Column(Date, nullable=True)
    note       = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(),
                        onupdate=func.now())

    __table_args__ = (
        # ເບີໂທຊ້ຳກັນໄດ້ຂ້າມຮ້ານ ແຕ່ພາຍໃນຮ້ານດຽວກັນຫ້າມຊ້ຳ ບໍ່ດັ່ງນັ້ນ login ຈະກຳກວມ
        UniqueConstraint("owner_id", "phone", name="uq_staff_owner_phone"),
        Index("ix_staff_owner_active", "owner_id", "active"),
    )


class Attendance(Base):
    """ໜຶ່ງແຖວ = ໜຶ່ງກະ (ເຂົ້າ → ອອກ)."""

    __tablename__ = "attendance_merchant"

    id       = Column(Integer, primary_key=True, index=True)
    staff_id = Column(Integer, ForeignKey("staff_merchant.id"), nullable=False, index=True)
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)

    work_date    = Column(Date, nullable=False, index=True)
    clock_in_at  = Column(DateTime(timezone=True), nullable=False)
    clock_out_at = Column(DateTime(timezone=True), nullable=True)

    # ພິກັດດິບ — ເກັບໄວ້ໃຫ້ກວດຄືນໄດ້ ບໍ່ແມ່ນເກັບແຕ່ "ຢູ່ໃນ/ນອກ"
    in_lat  = Column(Float, nullable=True)
    in_lng  = Column(Float, nullable=True)
    in_accuracy_m  = Column(Float, nullable=True)
    in_distance_m  = Column(Float, nullable=True)

    out_lat = Column(Float, nullable=True)
    out_lng = Column(Float, nullable=True)
    out_accuracy_m = Column(Float, nullable=True)
    out_distance_m = Column(Float, nullable=True)

    minutes_worked = Column(Integer, nullable=True)

    # ຂໍ້ສົງໄສທີ່ລະບົບພົບເອງ ເຊັ່ນ ພິກັດຊ້ຳເປັນະເປັນ, ຄວາມແມ່ນຢຳ 0, ຍ້າຍໄວເກີນຈິງ
    flags = Column(JSONB, nullable=True)
    note  = Column(Text, nullable=True)

    # ເຈົ້າຂອງຮ້ານແກ້ເວລາດ້ວຍມື — ຕ້ອງຮູ້ວ່າແຖວໃດຖືກແກ້
    edited_by_owner = Column(Boolean, nullable=False, default=False,
                             server_default="false")

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_attendance_staff_date", "staff_id", "work_date"),
        Index("ix_attendance_owner_date", "owner_id", "work_date"),
    )


class StaffAdjustment(Base):
    """ເງິນເພີ່ມ ຫຼື ເງິນຫັກ ຂອງພະນັກງານໃນເດືອນໃດໜຶ່ງ."""

    __tablename__ = "staff_adjustments_merchant"

    id       = Column(Integer, primary_key=True, index=True)
    staff_id = Column(Integer, ForeignKey("staff_merchant.id"), nullable=False, index=True)
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)

    # allowance | bonus | overtime  → ບວກ
    # advance | fine | deduction    → ຫັກ
    kind   = Column(String(16), nullable=False)
    amount = Column(BigInteger, nullable=False)
    note   = Column(Text, nullable=True)

    period_start = Column(Date, nullable=False, index=True)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        Index("ix_adj_staff_period", "staff_id", "period_start"),
    )


class PayrollRun(Base):
    """ຮອບຈ່າຍເງິນເດືອນຂອງໜຶ່ງເດືອນ."""

    __tablename__ = "payroll_runs_merchant"

    id       = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)

    period_start = Column(Date, nullable=False)
    period_end   = Column(Date, nullable=False)

    # draft = ຄິດສົດທຸກຄັ້ງ · finalised = ຕົວເລກຖືກແຊ່ແຂງ · paid = ຈ່າຍແລ້ວ
    status = Column(String(12), nullable=False, default="draft")

    total_gross = Column(BigInteger, nullable=False, default=0)
    total_net   = Column(BigInteger, nullable=False, default=0)

    finalised_at = Column(DateTime(timezone=True), nullable=True)
    paid_at      = Column(DateTime(timezone=True), nullable=True)
    # ລາຍຈ່າຍທີ່ສ້າງໃນບັນຊີຮ້ານຕອນຈ່າຍ — ກັນສ້າງຊ້ຳ
    expense_entry_id = Column(Integer, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("owner_id", "period_start", name="uq_payroll_owner_period"),
    )


class Payslip(Base):
    """ຕົວເລກທີ່ຖືກແຊ່ແຂງຕອນປິດຮອບ.

    ຕ້ອງແຊ່ແຂງ ບໍ່ແມ່ນຄິດສົດທຸກຄັ້ງ — ຖ້າເຈົ້າຂອງຮ້ານແກ້ເວລາເຂົ້າ-ອອກ
    ພາຍຫຼັງ ໃບເງິນເດືອນເດືອນທີ່ຈ່າຍໄປແລ້ວຕ້ອງບໍ່ປ່ຽນຕາມ.
    """

    __tablename__ = "payslips_merchant"

    id       = Column(Integer, primary_key=True, index=True)
    run_id   = Column(Integer, ForeignKey("payroll_runs_merchant.id"), nullable=False, index=True)
    staff_id = Column(Integer, ForeignKey("staff_merchant.id"), nullable=False, index=True)
    owner_id = Column(Integer, ForeignKey("shop_owners.id"), nullable=False, index=True)

    staff_name = Column(String(120), nullable=False)   # ສຳເນົາໄວ້ ເຜື່ອລຶບພະນັກງານ
    pay_type   = Column(String(10), nullable=False)

    days_worked    = Column(Integer, nullable=False, default=0)
    minutes_worked = Column(Integer, nullable=False, default=0)

    base_pay   = Column(BigInteger, nullable=False, default=0)
    additions  = Column(BigInteger, nullable=False, default=0)
    deductions = Column(BigInteger, nullable=False, default=0)
    net_pay    = Column(BigInteger, nullable=False, default=0)

    # ລາຍລະອຽດແຕ່ລະລາຍການ ເພື່ອໃຫ້ພະນັກງານກວດຄືນໄດ້
    lines = Column(JSONB, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    __table_args__ = (
        UniqueConstraint("run_id", "staff_id", name="uq_payslip_run_staff"),
    )
