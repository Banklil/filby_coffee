"""ຕັກກະການລົງເວລາ ແລະ ຄິດເງິນເດືອນ.

ທຸກການຕັດສິນວ່າ "ຢູ່ໃນລັດສະໝີຫຼືບໍ່" ເກີດຢູ່ server ສະເໝີ. Client ສົ່ງມາໄດ້ພຽງ
ພິກັດດິບ — ຖ້າປ່ອຍໃຫ້ client ບອກວ່າ "ຂ້ອຍຢູ່ໃນຮ້ານແລ້ວ" ພະນັກງານແກ້ຄ່ານັ້ນໄດ້ທັນທີ.
"""
from datetime import date, datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.security import decode_token
from ..database import get_db
from ..models.staff import Attendance, Staff

bearer = HTTPBearer()

DEFAULT_RADIUS_M = 150
ROUND_MINUTES = 15          # ປັດຊົ່ວໂມງເຮັດວຽກເປັນ 15 ນາທີ
MAX_SHIFT_HOURS = 16        # ກະທີ່ຍາວກວ່ານີ້ຖືວ່າລືມກົດອອກ
SUSPECT_SPEED_KMH = 150     # ໄວກວ່ານີ້ລະຫວ່າງສອງຄັ້ງ = ໄປບໍ່ໄດ້ຈິງ


# ── ໄລຍະທາງ ──────────────────────────────────────────────────────────
def distance_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Haversine — ໄລຍະທາງເປັນແມັດເທິງໜ້າໂລກ."""
    r = 6371000.0
    p1, p2 = radians(lat1), radians(lat2)
    dp = radians(lat2 - lat1)
    dl = radians(lng2 - lng1)
    a = sin(dp / 2) ** 2 + cos(p1) * cos(p2) * sin(dl / 2) ** 2
    return 2 * r * asin(sqrt(a))


# ── ການຢືນຢັນຕົວພະນັກງານ ─────────────────────────────────────────────
def get_staff(credentials: HTTPAuthorizationCredentials = Depends(bearer),
              db: Session = Depends(get_db)) -> Staff:
    """Token ຂອງພະນັກງານມີ sub = "staff:<id>" ເພື່ອບໍ່ໃຫ້ປົນກັບ token ເຈົ້າຂອງຮ້ານ."""
    payload = decode_token(credentials.credentials)
    if not payload or payload.get("type") == "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token ໝົດອາຍຸ")

    sub = str(payload.get("sub", ""))
    if not sub.startswith("staff:"):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED,
                            "ບັນຊີນີ້ບໍ່ມີສິດເຂົ້າເຖິງສ່ວນນີ້")
    try:
        staff_id = int(sub.split(":", 1)[1])
    except ValueError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token ບໍ່ຖືກຕ້ອງ")

    staff = db.scalar(select(Staff).where(Staff.id == staff_id, Staff.active.is_(True)))
    if not staff:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "ບໍ່ພົບບັນຊີ ຫຼື ຖືກປິດແລ້ວ")
    return staff


# ── ການກວດພິກັດ ──────────────────────────────────────────────────────
def check_location(owner, lat: Optional[float], lng: Optional[float],
                   accuracy: Optional[float]) -> tuple[float, list[str]]:
    """ຄືນ (ໄລຍະທາງເປັນແມັດ, ລາຍການຂໍ້ສົງໄສ). Raise ຖ້າຢູ່ນອກລັດສະໝີ."""
    flags: list[str] = []

    if owner.geo_lat is None or owner.geo_lng is None:
        raise HTTPException(400, "ຮ້ານຍັງບໍ່ໄດ້ຕັ້ງທີ່ຕັ້ງ — ໃຫ້ເຈົ້າຂອງຮ້ານຕັ້ງກ່ອນ")

    if lat is None or lng is None:
        raise HTTPException(400, "ເປີດການເຂົ້າເຖິງທີ່ຕັ້ງກ່ອນຈຶ່ງກົດເຂົ້າວຽກໄດ້")

    radius = int(owner.geo_radius_m or DEFAULT_RADIUS_M)
    d = distance_m(owner.geo_lat, owner.geo_lng, lat, lng)

    # ຄວາມແມ່ນຢຳຕ່ຳ = ອາດຢູ່ໃນຮ້ານແທ້ ຈຶ່ງຜ່ອນຜັນໃຫ້ ແຕ່ບັນທຶກໄວ້
    tolerance = min(float(accuracy or 0), 100.0)
    if d > radius + tolerance:
        raise HTTPException(403, {
            "code": "outside_geofence",
            "distance_m": round(d),
            "radius_m": radius,
            "message": f"ທ່ານຢູ່ຫ່າງຈາກຮ້ານ {round(d):,} ແມັດ "
                       f"(ອະນຸຍາດ {radius:,} ແມັດ) — ກົດເຂົ້າວຽກບໍ່ໄດ້",
        })

    # ຄວາມແມ່ນຢຳ 0 ບໍ່ເກີດຂຶ້ນຈາກ GPS ຈິງ — ມັກມາຈາກການຕັ້ງຄ່າປອມໃນ browser
    if accuracy is not None and accuracy <= 0:
        flags.append("accuracy_zero")
    if accuracy is None:
        flags.append("accuracy_missing")
    if tolerance > 0 and d > radius:
        flags.append("passed_on_tolerance")
    return d, flags


def spoofing_flags(db: Session, staff_id: int, lat: float, lng: float,
                   now: datetime) -> list[str]:
    """ຫາຮ່ອງຮອຍການປອມພິກັດ ໂດຍທຽບກັບການກົດຄັ້ງກ່ອນ."""
    flags: list[str] = []
    prev = db.scalar(
        select(Attendance).where(Attendance.staff_id == staff_id)
        .order_by(Attendance.clock_in_at.desc()).limit(1)
    )
    if not prev or prev.in_lat is None:
        return flags

    # ພິກັດຊ້ຳກັນເປັນະເປັນທຸກທົດສະນິຍົມ = ບໍ່ແມ່ນ GPS ຈິງ
    if abs(prev.in_lat - lat) < 1e-7 and abs(prev.in_lng - lng) < 1e-7:
        flags.append("identical_coords")

    last_at = prev.clock_out_at or prev.clock_in_at
    if last_at:
        if last_at.tzinfo is None:
            last_at = last_at.replace(tzinfo=timezone.utc)
        hours = max((now - last_at).total_seconds() / 3600, 1e-6)
        km = distance_m(prev.in_lat, prev.in_lng, lat, lng) / 1000
        if km / hours > SUSPECT_SPEED_KMH:
            flags.append("impossible_travel")
    return flags


# ── ຊົ່ວໂມງເຮັດວຽກ ────────────────────────────────────────────────────
def worked_minutes(clock_in: datetime, clock_out: datetime) -> int:
    """ນາທີທີ່ເຮັດວຽກ ປັດເປັນຊ່ວງ ROUND_MINUTES."""
    raw = (clock_out - clock_in).total_seconds() / 60
    if raw <= 0:
        return 0
    raw = min(raw, MAX_SHIFT_HOURS * 60)
    return int(round(raw / ROUND_MINUTES) * ROUND_MINUTES)


# ── ຮອບເງິນເດືອນ ──────────────────────────────────────────────────────
def period_bounds(year: int, month: int) -> tuple[date, date]:
    start = date(year, month, 1)
    end = (date(year + 1, 1, 1) if month == 12 else date(year, month + 1, 1)) \
        - timedelta(days=1)
    return start, end


def compute_payslip(db: Session, staff: Staff, start: date, end: date) -> dict:
    """ຄິດເງິນເດືອນຂອງພະນັກງານໜຶ່ງຄົນໃນຮອບໜຶ່ງ.

    ເງິນເດືອນປະຈຳ : ໃຊ້ເງິນເດືອນຄົງທີ່ ບໍ່ຫັກຕາມມື້ຂາດ — ຖ້າຢາກຫັກ ໃຫ້ເຈົ້າຂອງຮ້ານ
                   ເພີ່ມລາຍການຫັກເອງ ຈະໄດ້ມີເຫດຜົນບັນທຶກໄວ້ ແລະ ໂຕ້ແຍ້ງໄດ້.
    ລາຍຊົ່ວໂມງ   : ຊົ່ວໂມງຈາກການລົງເວລາ × ອັດຕາຕໍ່ຊົ່ວໂມງ.
    """
    from ..models.staff import StaffAdjustment

    rows = db.scalars(
        select(Attendance).where(
            Attendance.staff_id == staff.id,
            Attendance.work_date >= start,
            Attendance.work_date <= end,
        )
    ).all()

    minutes = sum(int(r.minutes_worked or 0) for r in rows)
    days = len({r.work_date for r in rows if (r.minutes_worked or 0) > 0})
    lines: list[dict] = []

    if staff.pay_type == "hourly":
        hours = minutes / 60
        base = int(round(hours * int(staff.hourly_rate or 0)))
        lines.append({
            "label": f"ຊົ່ວໂມງເຮັດວຽກ {hours:.2f} ຊມ × {int(staff.hourly_rate or 0):,}",
            "amount": base,
        })
    else:
        base = int(staff.base_salary or 0)
        lines.append({"label": "ເງິນເດືອນພື້ນຖານ", "amount": base})

    adjustments = db.scalars(
        select(StaffAdjustment).where(
            StaffAdjustment.staff_id == staff.id,
            StaffAdjustment.period_start == start,
        )
    ).all()

    PLUS = {"allowance", "bonus", "overtime"}
    additions = deductions = 0
    labels = {
        "allowance": "ເງິນອຸດໜູນ", "bonus": "ໂບນັດ", "overtime": "ລ່ວງເວລາ",
        "advance": "ເບີກລ່ວງໜ້າ", "fine": "ຄ່າປັບ", "deduction": "ຫັກອື່ນໆ",
    }
    for a in adjustments:
        amt = int(a.amount)
        signed = amt if a.kind in PLUS else -amt
        if a.kind in PLUS:
            additions += amt
        else:
            deductions += amt
        lines.append({
            "label": labels.get(a.kind, a.kind) + (f" — {a.note}" if a.note else ""),
            "amount": signed,
        })

    net = base + additions - deductions
    return {
        "staff_id": staff.id,
        "staff_name": staff.name,
        "pay_type": staff.pay_type,
        "days_worked": days,
        "minutes_worked": minutes,
        "hours_worked": round(minutes / 60, 2),
        "base_pay": base,
        "additions": additions,
        "deductions": deductions,
        "net_pay": net,
        "lines": lines,
    }
