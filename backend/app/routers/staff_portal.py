"""ໜ້າຕ່າງຂອງພະນັກງານ — ເຮັດໄດ້ພຽງສອງຢ່າງ.

ກົດເຂົ້າ-ອອກວຽກ ແລະ ເບິ່ງເງິນເດືອນຂອງຕົນເອງ. ບໍ່ມີ endpoint ໃດຢູ່ນີ້ທີ່ເປີດ
ຂໍ້ມູນຍອດຂາຍ, ສິນເຊື່ອ ຫຼື ພະນັກງານຄົນອື່ນ.
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.security import create_access_token, create_refresh_token, verify_password
from ..core.staffing import (
    check_location, get_staff, spoofing_flags, worked_minutes,
)
from ..core.timeutil import lao_now
from ..database import get_db
from ..models.shop_owner import ShopOwner
from ..models.staff import Attendance, Payslip, Staff

router = APIRouter(prefix="/api/staff", tags=["staff-portal"])


class StaffLogin(BaseModel):
    phone: str = Field(min_length=5, max_length=30)
    pin: str = Field(min_length=4, max_length=12)


class Punch(BaseModel):
    lat: Optional[float] = None
    lng: Optional[float] = None
    accuracy: Optional[float] = None


def _staff_out(s: Staff) -> dict:
    return {
        "id": s.id, "name": s.name, "phone": s.phone, "role": s.role,
        "pay_type": s.pay_type,
        "base_salary": int(s.base_salary or 0),
        "hourly_rate": int(s.hourly_rate or 0),
    }


@router.post("/login")
def staff_login(body: StaffLogin, db: Session = Depends(get_db)):
    # ເບີໂທຊ້ຳກັນໄດ້ຂ້າມຮ້ານ — ຈຶ່ງຕ້ອງລອງທຽບ PIN ກັບທຸກແຖວທີ່ເບີຕົງກັນ
    rows = db.scalars(
        select(Staff).where(Staff.phone == body.phone.strip(), Staff.active.is_(True))
    ).all()
    staff = next((s for s in rows if verify_password(body.pin, s.pin_hash)), None)
    if not staff:
        raise HTTPException(401, "ເບີໂທ ຫຼື PIN ບໍ່ຖືກຕ້ອງ")

    sub = f"staff:{staff.id}"
    return {
        "access_token": create_access_token({"sub": sub, "role": "staff"}),
        "refresh_token": create_refresh_token({"sub": sub, "role": "staff"}),
        "token_type": "bearer",
        "staff": _staff_out(staff),
    }


@router.get("/me")
def me(staff: Staff = Depends(get_staff), db: Session = Depends(get_db)):
    owner = db.get(ShopOwner, staff.owner_id)
    open_row = db.scalar(
        select(Attendance).where(
            Attendance.staff_id == staff.id, Attendance.clock_out_at.is_(None)
        ).order_by(Attendance.clock_in_at.desc())
    )
    return {
        **_staff_out(staff),
        "shop_name": owner.shop_name if owner else None,
        "geofence_ready": bool(owner and owner.geo_lat is not None),
        "radius_m": int(owner.geo_radius_m or 150) if owner else 150,
        "open_shift": None if not open_row else {
            "id": open_row.id,
            "clock_in_at": open_row.clock_in_at.isoformat(),
        },
    }


@router.post("/clock-in")
def clock_in(body: Punch, staff: Staff = Depends(get_staff),
             db: Session = Depends(get_db)):
    owner = db.get(ShopOwner, staff.owner_id)
    if not owner:
        raise HTTPException(400, "ບໍ່ພົບຮ້ານ")

    already = db.scalar(
        select(Attendance).where(
            Attendance.staff_id == staff.id, Attendance.clock_out_at.is_(None))
    )
    if already:
        raise HTTPException(409, "ທ່ານກົດເຂົ້າວຽກຢູ່ແລ້ວ — ກົດອອກກ່ອນ")

    now = datetime.now(timezone.utc)
    d, flags = check_location(owner, body.lat, body.lng, body.accuracy)
    flags += spoofing_flags(db, staff.id, body.lat, body.lng, now)

    row = Attendance(
        staff_id=staff.id, owner_id=owner.id,
        work_date=lao_now().date(), clock_in_at=now,
        in_lat=body.lat, in_lng=body.lng,
        in_accuracy_m=body.accuracy, in_distance_m=d,
        flags=flags or None,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return {"id": row.id, "clock_in_at": row.clock_in_at.isoformat(),
            "distance_m": round(d), "message": "ກົດເຂົ້າວຽກສຳເລັດ"}


@router.post("/clock-out")
def clock_out(body: Punch, staff: Staff = Depends(get_staff),
              db: Session = Depends(get_db)):
    owner = db.get(ShopOwner, staff.owner_id)
    row = db.scalar(
        select(Attendance).where(
            Attendance.staff_id == staff.id, Attendance.clock_out_at.is_(None)
        ).order_by(Attendance.clock_in_at.desc())
    )
    if not row:
        raise HTTPException(409, "ຍັງບໍ່ໄດ້ກົດເຂົ້າວຽກ")

    now = datetime.now(timezone.utc)
    d, flags = check_location(owner, body.lat, body.lng, body.accuracy)

    row.clock_out_at = now
    row.out_lat, row.out_lng = body.lat, body.lng
    row.out_accuracy_m, row.out_distance_m = body.accuracy, d

    start = row.clock_in_at
    if start.tzinfo is None:
        start = start.replace(tzinfo=timezone.utc)
    row.minutes_worked = worked_minutes(start, now)

    if flags:
        row.flags = (row.flags or []) + [f"out_{f}" for f in flags]
    db.commit()

    return {
        "id": row.id,
        "minutes_worked": row.minutes_worked,
        "hours_worked": round(row.minutes_worked / 60, 2),
        "message": "ກົດອອກວຽກສຳເລັດ",
    }


@router.get("/attendance")
def my_attendance(year: Optional[int] = None, month: Optional[int] = None,
                  staff: Staff = Depends(get_staff),
                  db: Session = Depends(get_db)):
    from ..core.staffing import period_bounds
    today = lao_now().date()
    start, end = period_bounds(year or today.year, month or today.month)

    rows = db.scalars(
        select(Attendance).where(
            Attendance.staff_id == staff.id,
            Attendance.work_date >= start, Attendance.work_date <= end,
        ).order_by(Attendance.clock_in_at.desc())
    ).all()

    minutes = sum(int(r.minutes_worked or 0) for r in rows)
    return {
        "period": start.isoformat(),
        "total_minutes": minutes,
        "total_hours": round(minutes / 60, 2),
        "days_worked": len({r.work_date for r in rows if (r.minutes_worked or 0) > 0}),
        "items": [{
            "id": r.id,
            "date": r.work_date.isoformat(),
            "clock_in_at": r.clock_in_at.isoformat() if r.clock_in_at else None,
            "clock_out_at": r.clock_out_at.isoformat() if r.clock_out_at else None,
            "minutes_worked": int(r.minutes_worked or 0),
            "edited": bool(r.edited_by_owner),
        } for r in rows],
    }


@router.get("/payslips")
def my_payslips(staff: Staff = Depends(get_staff), db: Session = Depends(get_db)):
    """ສະເພາະໃບທີ່ປິດຮອບແລ້ວ — ຮ່າງທີ່ຍັງບໍ່ທັນສະຫຼຸບບໍ່ຄວນໃຫ້ພະນັກງານເຫັນ."""
    from ..models.staff import PayrollRun

    rows = db.execute(
        select(Payslip, PayrollRun)
        .join(PayrollRun, PayrollRun.id == Payslip.run_id)
        .where(Payslip.staff_id == staff.id,
               PayrollRun.status.in_(("finalised", "paid")))
        .order_by(PayrollRun.period_start.desc())
    ).all()

    return [{
        "period": run.period_start.isoformat(),
        "status": run.status,
        "paid_at": run.paid_at.isoformat() if run.paid_at else None,
        "days_worked": p.days_worked,
        "hours_worked": round((p.minutes_worked or 0) / 60, 2),
        "base_pay": int(p.base_pay),
        "additions": int(p.additions),
        "deductions": int(p.deductions),
        "net_pay": int(p.net_pay),
        "lines": p.lines or [],
    } for p, run in rows]
