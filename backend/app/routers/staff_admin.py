"""ຝັ່ງເຈົ້າຂອງຮ້ານ — ຈັດການພະນັກງານ, ເວລາເຮັດວຽກ ແລະ ເງິນເດືອນ."""
from datetime import date, datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..core.security import get_password_hash
from ..core.staffing import compute_payslip, period_bounds, worked_minutes
from ..core.timeutil import lao_now
from ..database import get_db
from ..models.shop_entry import ShopEntry
from ..models.shop_owner import ShopOwner
from ..models.staff import (
    Attendance, PayrollRun, Payslip, Staff, StaffAdjustment,
)
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/shop/staff", tags=["staff-admin"])

PAYROLL_EXPENSE_CATEGORY = "ຄ່າແຮງງານ"


# ── Schemas ──────────────────────────────────────────────────────────
class StaffIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    phone: str = Field(min_length=5, max_length=30)
    pin: str = Field(min_length=4, max_length=12)
    role: Optional[str] = Field(default=None, max_length=60)
    pay_type: Literal["monthly", "hourly"] = "monthly"
    base_salary: int = Field(default=0, ge=0, le=1_000_000_000)
    hourly_rate: int = Field(default=0, ge=0, le=10_000_000)
    started_on: Optional[date] = None
    note: Optional[str] = Field(default=None, max_length=500)


class StaffPatch(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    phone: Optional[str] = Field(default=None, min_length=5, max_length=30)
    pin: Optional[str] = Field(default=None, min_length=4, max_length=12)
    role: Optional[str] = Field(default=None, max_length=60)
    pay_type: Optional[Literal["monthly", "hourly"]] = None
    base_salary: Optional[int] = Field(default=None, ge=0, le=1_000_000_000)
    hourly_rate: Optional[int] = Field(default=None, ge=0, le=10_000_000)
    active: Optional[bool] = None
    note: Optional[str] = Field(default=None, max_length=500)


class GeofenceIn(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    radius_m: int = Field(default=150, ge=30, le=2000)


class AdjustmentIn(BaseModel):
    staff_id: int
    kind: Literal["allowance", "bonus", "overtime", "advance", "fine", "deduction"]
    amount: int = Field(gt=0, le=1_000_000_000)
    note: Optional[str] = Field(default=None, max_length=300)
    period: Optional[date] = None      # ວັນທີ 1 ຂອງເດືອນ


class AttendancePatch(BaseModel):
    clock_in_at: Optional[datetime] = None
    clock_out_at: Optional[datetime] = None
    note: Optional[str] = Field(default=None, max_length=300)


def _out(s: Staff) -> dict:
    return {
        "id": s.id, "name": s.name, "phone": s.phone, "role": s.role,
        "pay_type": s.pay_type,
        "base_salary": int(s.base_salary or 0),
        "hourly_rate": int(s.hourly_rate or 0),
        "active": bool(s.active),
        "started_on": s.started_on.isoformat() if s.started_on else None,
        "note": s.note,
    }


def _own(db: Session, owner: ShopOwner, staff_id: int) -> Staff:
    s = db.scalar(select(Staff).where(
        Staff.id == staff_id, Staff.owner_id == owner.id))
    if not s:
        raise HTTPException(404, "ບໍ່ພົບພະນັກງານ")
    return s


# ── ທີ່ຕັ້ງຮ້ານ ───────────────────────────────────────────────────────
@router.get("/geofence")
def get_geofence(owner: ShopOwner = Depends(_get_owner)):
    return {
        "lat": owner.geo_lat, "lng": owner.geo_lng,
        "radius_m": int(owner.geo_radius_m or 150),
        "ready": owner.geo_lat is not None,
    }


@router.put("/geofence")
def set_geofence(body: GeofenceIn, db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    owner.geo_lat, owner.geo_lng = body.lat, body.lng
    owner.geo_radius_m = body.radius_m
    db.commit()
    return {"lat": owner.geo_lat, "lng": owner.geo_lng,
            "radius_m": owner.geo_radius_m, "ready": True}


# ── ພະນັກງານ ─────────────────────────────────────────────────────────
@router.get("")
def list_staff(include_inactive: bool = False, db: Session = Depends(get_db),
               owner: ShopOwner = Depends(_get_owner)):
    q = select(Staff).where(Staff.owner_id == owner.id)
    if not include_inactive:
        q = q.where(Staff.active.is_(True))
    return [_out(s) for s in db.scalars(q.order_by(Staff.name)).all()]


@router.post("", status_code=201)
def create_staff(body: StaffIn, db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    if body.pay_type == "monthly" and body.base_salary <= 0:
        raise HTTPException(400, "ພະນັກງານລາຍເດືອນຕ້ອງມີເງິນເດືອນ")
    if body.pay_type == "hourly" and body.hourly_rate <= 0:
        raise HTTPException(400, "ພະນັກງານລາຍຊົ່ວໂມງຕ້ອງມີອັດຕາຕໍ່ຊົ່ວໂມງ")
    if not body.pin.isdigit():
        raise HTTPException(400, "PIN ຕ້ອງເປັນຕົວເລກເທົ່ານັ້ນ")

    s = Staff(
        owner_id=owner.id, name=body.name.strip(), phone=body.phone.strip(),
        pin_hash=get_password_hash(body.pin), role=body.role,
        pay_type=body.pay_type, base_salary=body.base_salary,
        hourly_rate=body.hourly_rate, started_on=body.started_on, note=body.note,
    )
    db.add(s)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "ເບີໂທນີ້ຖືກໃຊ້ກັບພະນັກງານຄົນອື່ນໃນຮ້ານແລ້ວ")
    db.refresh(s)
    return _out(s)


@router.patch("/{staff_id}")
def update_staff(staff_id: int, body: StaffPatch, db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    s = _own(db, owner, staff_id)
    data = body.model_dump(exclude_unset=True)

    if "pin" in data and data["pin"]:
        if not str(data["pin"]).isdigit():
            raise HTTPException(400, "PIN ຕ້ອງເປັນຕົວເລກເທົ່ານັ້ນ")
        s.pin_hash = get_password_hash(data.pop("pin"))
    data.pop("pin", None)

    for k, v in data.items():
        setattr(s, k, v.strip() if isinstance(v, str) else v)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "ເບີໂທນີ້ຖືກໃຊ້ກັບພະນັກງານຄົນອື່ນໃນຮ້ານແລ້ວ")
    db.refresh(s)
    return _out(s)


@router.delete("/{staff_id}")
def deactivate_staff(staff_id: int, db: Session = Depends(get_db),
                     owner: ShopOwner = Depends(_get_owner)):
    """ປິດການໃຊ້ງານ ບໍ່ແມ່ນລຶບ — ປະຫວັດເວລາ ແລະ ໃບເງິນເດືອນຕ້ອງຍັງຢູ່."""
    s = _own(db, owner, staff_id)
    s.active = False
    db.commit()
    return {"ok": True, "message": f"ປິດການໃຊ້ງານ {s.name} ແລ້ວ"}


# ── ເວລາເຮັດວຽກ ──────────────────────────────────────────────────────
@router.get("/attendance")
def attendance(year: Optional[int] = None, month: Optional[int] = None,
               staff_id: Optional[int] = None,
               db: Session = Depends(get_db),
               owner: ShopOwner = Depends(_get_owner)):
    today = lao_now().date()
    start, end = period_bounds(year or today.year, month or today.month)

    q = select(Attendance, Staff).join(Staff, Staff.id == Attendance.staff_id).where(
        Attendance.owner_id == owner.id,
        Attendance.work_date >= start, Attendance.work_date <= end,
    )
    if staff_id:
        q = q.where(Attendance.staff_id == staff_id)

    rows = db.execute(q.order_by(Attendance.clock_in_at.desc())).all()
    return {
        "period": start.isoformat(),
        "items": [{
            "id": a.id, "staff_id": a.staff_id, "staff_name": s.name,
            "date": a.work_date.isoformat(),
            "clock_in_at": a.clock_in_at.isoformat() if a.clock_in_at else None,
            "clock_out_at": a.clock_out_at.isoformat() if a.clock_out_at else None,
            "minutes_worked": int(a.minutes_worked or 0),
            "in_distance_m": round(a.in_distance_m) if a.in_distance_m is not None else None,
            "flags": a.flags or [],
            "edited": bool(a.edited_by_owner),
        } for a, s in rows],
    }


@router.patch("/attendance/{row_id}")
def edit_attendance(row_id: int, body: AttendancePatch,
                    db: Session = Depends(get_db),
                    owner: ShopOwner = Depends(_get_owner)):
    """ແກ້ເວລາດ້ວຍມື — ເຊັ່ນ ພະນັກງານລືມກົດອອກ."""
    a = db.scalar(select(Attendance).where(
        Attendance.id == row_id, Attendance.owner_id == owner.id))
    if not a:
        raise HTTPException(404, "ບໍ່ພົບລາຍການ")

    if body.clock_in_at:
        a.clock_in_at = body.clock_in_at
    if body.clock_out_at:
        a.clock_out_at = body.clock_out_at
    if body.note is not None:
        a.note = body.note

    if a.clock_in_at and a.clock_out_at:
        ci, co = a.clock_in_at, a.clock_out_at
        if ci.tzinfo is None:
            ci = ci.replace(tzinfo=timezone.utc)
        if co.tzinfo is None:
            co = co.replace(tzinfo=timezone.utc)
        if co <= ci:
            raise HTTPException(400, "ເວລາອອກຕ້ອງຫຼັງເວລາເຂົ້າ")
        a.minutes_worked = worked_minutes(ci, co)

    a.edited_by_owner = True
    db.commit()
    return {"ok": True, "minutes_worked": int(a.minutes_worked or 0)}


# ── ເງິນເພີ່ມ / ເງິນຫັກ ────────────────────────────────────────────────
@router.get("/adjustments")
def list_adjustments(year: Optional[int] = None, month: Optional[int] = None,
                     db: Session = Depends(get_db),
                     owner: ShopOwner = Depends(_get_owner)):
    today = lao_now().date()
    start, _ = period_bounds(year or today.year, month or today.month)
    rows = db.scalars(select(StaffAdjustment).where(
        StaffAdjustment.owner_id == owner.id,
        StaffAdjustment.period_start == start,
    ).order_by(StaffAdjustment.id.desc())).all()
    return [{"id": r.id, "staff_id": r.staff_id, "kind": r.kind,
             "amount": int(r.amount), "note": r.note,
             "period": r.period_start.isoformat()} for r in rows]


@router.post("/adjustments", status_code=201)
def add_adjustment(body: AdjustmentIn, db: Session = Depends(get_db),
                   owner: ShopOwner = Depends(_get_owner)):
    _own(db, owner, body.staff_id)
    today = lao_now().date()
    period = (body.period or today).replace(day=1)

    run = db.scalar(select(PayrollRun).where(
        PayrollRun.owner_id == owner.id, PayrollRun.period_start == period))
    if run and run.status != "draft":
        raise HTTPException(409, "ຮອບເດືອນນີ້ປິດແລ້ວ — ແກ້ໄຂບໍ່ໄດ້")

    a = StaffAdjustment(staff_id=body.staff_id, owner_id=owner.id,
                        kind=body.kind, amount=body.amount,
                        note=body.note, period_start=period)
    db.add(a)
    db.commit()
    db.refresh(a)
    return {"id": a.id, "kind": a.kind, "amount": int(a.amount),
            "period": a.period_start.isoformat()}


@router.delete("/adjustments/{adj_id}")
def delete_adjustment(adj_id: int, db: Session = Depends(get_db),
                      owner: ShopOwner = Depends(_get_owner)):
    a = db.scalar(select(StaffAdjustment).where(
        StaffAdjustment.id == adj_id, StaffAdjustment.owner_id == owner.id))
    if not a:
        raise HTTPException(404, "ບໍ່ພົບລາຍການ")
    run = db.scalar(select(PayrollRun).where(
        PayrollRun.owner_id == owner.id, PayrollRun.period_start == a.period_start))
    if run and run.status != "draft":
        raise HTTPException(409, "ຮອບເດືອນນີ້ປິດແລ້ວ — ແກ້ໄຂບໍ່ໄດ້")
    db.delete(a)
    db.commit()
    return {"ok": True}


# ── ເງິນເດືອນ ─────────────────────────────────────────────────────────
@router.get("/payroll")
def payroll(year: Optional[int] = None, month: Optional[int] = None,
            db: Session = Depends(get_db),
            owner: ShopOwner = Depends(_get_owner)):
    """ຮ່າງຄິດສົດ; ຖ້າປິດຮອບແລ້ວຄືນຕົວເລກທີ່ແຊ່ແຂງໄວ້."""
    today = lao_now().date()
    start, end = period_bounds(year or today.year, month or today.month)

    run = db.scalar(select(PayrollRun).where(
        PayrollRun.owner_id == owner.id, PayrollRun.period_start == start))

    if run and run.status in ("finalised", "paid"):
        slips = db.scalars(select(Payslip).where(Payslip.run_id == run.id)).all()
        items = [{
            "staff_id": p.staff_id, "staff_name": p.staff_name,
            "pay_type": p.pay_type, "days_worked": p.days_worked,
            "hours_worked": round((p.minutes_worked or 0) / 60, 2),
            "base_pay": int(p.base_pay), "additions": int(p.additions),
            "deductions": int(p.deductions), "net_pay": int(p.net_pay),
            "lines": p.lines or [],
        } for p in slips]
    else:
        staff = db.scalars(select(Staff).where(
            Staff.owner_id == owner.id, Staff.active.is_(True))).all()
        items = [compute_payslip(db, s, start, end) for s in staff]

    return {
        "period": start.isoformat(),
        "period_end": end.isoformat(),
        "status": run.status if run else "draft",
        "paid_at": run.paid_at.isoformat() if run and run.paid_at else None,
        "total_gross": sum(i["base_pay"] + i["additions"] for i in items),
        "total_net": sum(i["net_pay"] for i in items),
        "items": items,
    }


@router.post("/payroll/finalise")
def finalise(year: Optional[int] = None, month: Optional[int] = None,
             db: Session = Depends(get_db),
             owner: ShopOwner = Depends(_get_owner)):
    """ແຊ່ແຂງຕົວເລກ. ຫຼັງຈາກນີ້ ການແກ້ເວລາຈະບໍ່ກະທົບໃບເງິນເດືອນນີ້ອີກ."""
    today = lao_now().date()
    start, end = period_bounds(year or today.year, month or today.month)

    run = db.scalar(select(PayrollRun).where(
        PayrollRun.owner_id == owner.id, PayrollRun.period_start == start))
    if run and run.status != "draft":
        raise HTTPException(409, "ຮອບເດືອນນີ້ປິດແລ້ວ")

    staff = db.scalars(select(Staff).where(
        Staff.owner_id == owner.id, Staff.active.is_(True))).all()
    if not staff:
        raise HTTPException(400, "ຍັງບໍ່ມີພະນັກງານ")

    if not run:
        run = PayrollRun(owner_id=owner.id, period_start=start, period_end=end)
        db.add(run)
        db.flush()

    gross = net = 0
    for s in staff:
        c = compute_payslip(db, s, start, end)
        db.add(Payslip(
            run_id=run.id, staff_id=s.id, owner_id=owner.id,
            staff_name=c["staff_name"], pay_type=c["pay_type"],
            days_worked=c["days_worked"], minutes_worked=c["minutes_worked"],
            base_pay=c["base_pay"], additions=c["additions"],
            deductions=c["deductions"], net_pay=c["net_pay"], lines=c["lines"],
        ))
        gross += c["base_pay"] + c["additions"]
        net += c["net_pay"]

    run.status = "finalised"
    run.total_gross, run.total_net = gross, net
    run.finalised_at = datetime.now(timezone.utc)
    db.commit()
    return {"status": "finalised", "total_net": net, "staff_count": len(staff)}


@router.post("/payroll/pay")
def mark_paid(year: Optional[int] = None, month: Optional[int] = None,
              db: Session = Depends(get_db),
              owner: ShopOwner = Depends(_get_owner)):
    """ໝາຍວ່າຈ່າຍແລ້ວ ແລະ ບັນທຶກເປັນລາຍຈ່າຍໃນບັນຊີຮ້ານໃຫ້ອັດຕະໂນມັດ."""
    today = lao_now().date()
    start, _ = period_bounds(year or today.year, month or today.month)

    run = db.scalar(select(PayrollRun).where(
        PayrollRun.owner_id == owner.id, PayrollRun.period_start == start))
    if not run or run.status == "draft":
        raise HTTPException(409, "ຕ້ອງປິດຮອບກ່ອນຈຶ່ງໝາຍວ່າຈ່າຍໄດ້")
    if run.status == "paid":
        return {"status": "paid", "already": True}

    # ບັນທຶກລົງບັນຊີຮ້ານ ເພື່ອບໍ່ໃຫ້ຕ້ອງພິມຊ້ຳ ແລະ ໃຫ້ກຳໄລສຸດທິຖືກຕ້ອງ
    entry = ShopEntry(
        owner_id=owner.id, type="expense", category=PAYROLL_EXPENSE_CATEGORY,
        amount=int(run.total_net), entry_date=lao_now().date(),
        note=f"ເງິນເດືອນ {start.month}/{start.year}",
    )
    db.add(entry)
    db.flush()

    run.status = "paid"
    run.paid_at = datetime.now(timezone.utc)
    run.expense_entry_id = entry.id
    db.commit()
    return {"status": "paid", "total_net": int(run.total_net),
            "expense_entry_id": entry.id,
            "message": "ບັນທຶກເປັນລາຍຈ່າຍໃນບັນຊີຮ້ານແລ້ວ"}


@router.get("/payroll/history")
def history(db: Session = Depends(get_db), owner: ShopOwner = Depends(_get_owner)):
    runs = db.scalars(select(PayrollRun).where(
        PayrollRun.owner_id == owner.id
    ).order_by(PayrollRun.period_start.desc()).limit(24)).all()
    return [{
        "period": r.period_start.isoformat(),
        "status": r.status,
        "total_gross": int(r.total_gross or 0),
        "total_net": int(r.total_net or 0),
        "paid_at": r.paid_at.isoformat() if r.paid_at else None,
    } for r in runs]
