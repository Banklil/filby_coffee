"""ກວດຮ່ອງຮອຍການປອມພິກັດ GPS.

ຫຼັກການ: ການກົດຢູ່ບ່ອນເກົ່າຊ້ຳໆ **ບໍ່ແມ່ນ** ຂໍ້ສົງໄສ — ພະນັກງານເຮັດວຽກຮ້ານດຽວກັນ
ທຸກມື້ ຈຶ່ງຕ້ອງກົດຢູ່ບ່ອນເກົ່າຢູ່ແລ້ວ.

ສັນຍານທີ່ແທ້ຈິງຄື **ພິກັດບໍ່ແກວ່ງເລີຍ**. GPS ຈິງມີຄວາມຄາດເຄື່ອນສະເໝີ —
ຢືນຢູ່ບ່ອນເກົ່າກົດ 20 ເທື່ອ ຈະໄດ້ 20 ພິກັດທີ່ຕ່າງກັນ 5–30 ແມັດ. ແອັບປອມພິກັດ
ສົ່ງຄ່າດຽວກັນເປັນະເປັນທຸກເທື່ອ ເພາະມັນເປັນຕົວເລກທີ່ຕັ້ງໄວ້ ບໍ່ແມ່ນການວັດ.
"""
from statistics import median
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..core.staffing import distance_m
from ..database import get_db
from ..models.shop_owner import ShopOwner
from ..models.staff import Attendance, Staff
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/shop/staff/audit", tags=["staff-admin"])

# ຂອບເຂດຕັດສິນ
MIN_PUNCHES = 4          # ໜ້ອຍກວ່ານີ້ ຂໍ້ມູນບໍ່ພຽງພໍທີ່ຈະສະຫຼຸບ
LOW_SPREAD_M = 3.0       # ແກວ່ງໜ້ອຍກວ່ານີ້ = ບໍ່ຄືການວັດຈິງ
UNIQUE_RATIO_BAD = 0.5   # ພິກັດຊ້ຳເກີນເຄິ່ງ = ໜ້າສົງໄສ


def _key(lat: float, lng: float) -> tuple:
    """ປັດເປັນ 7 ທົດສະນິຍົມ ≈ 1 ຊັງຕີແມັດ — GPS ຈິງບໍ່ເຄີຍຊ້ຳລະດັບນີ້."""
    return (round(lat, 7), round(lng, 7))


def _analyse(rows: list[Attendance]) -> dict:
    pts = [(r.in_lat, r.in_lng) for r in rows
           if r.in_lat is not None and r.in_lng is not None]
    n = len(pts)
    if n == 0:
        return {"punches": 0, "verdict": "no_data", "reasons": [], "score": 0}

    uniq = {_key(a, b) for a, b in pts}
    unique_ratio = len(uniq) / n

    # ການແກວ່ງສູງສຸດ — ໄລຍະທາງລະຫວ່າງສອງຈຸດທີ່ໄກກັນທີ່ສຸດ
    spread = 0.0
    for i in range(n):
        for j in range(i + 1, n):
            spread = max(spread, distance_m(pts[i][0], pts[i][1],
                                            pts[j][0], pts[j][1]))

    accs = [float(r.in_accuracy_m) for r in rows if r.in_accuracy_m is not None]
    zero_acc = sum(1 for a in accs if a <= 0)
    med_acc = median(accs) if accs else None

    reasons, score = [], 0
    if n >= MIN_PUNCHES:
        if spread < LOW_SPREAD_M:
            score += 50
            reasons.append(
                f"ພິກັດແກວ່ງພຽງ {spread:.1f} ມ ໃນ {n} ຄັ້ງ — GPS ຈິງແກວ່ງ 5–30 ມ")
        if unique_ratio <= UNIQUE_RATIO_BAD:
            score += 30
            reasons.append(
                f"ພິກັດຊ້ຳກັນເປັນະເປັນ {n - len(uniq)}/{n} ຄັ້ງ")
    if zero_acc:
        score += 25
        reasons.append(f"ຄວາມແມ່ນຢຳລາຍງານເປັນ 0 ຢູ່ {zero_acc} ຄັ້ງ")
    if accs and med_acc is not None and med_acc <= 1:
        score += 15
        reasons.append(f"ຄວາມແມ່ນຢຳກາງພຽງ {med_acc:.1f} ມ — ດີເກີນຄວາມເປັນຈິງ")

    flagged = sum(1 for r in rows if r.flags)
    if flagged:
        reasons.append(f"ລະບົບໝາຍໄວ້ຕອນກົດ {flagged} ຄັ້ງ")

    verdict = "high" if score >= 60 else "medium" if score >= 30 else "low"
    if n < MIN_PUNCHES:
        verdict, reasons = "insufficient", ["ຂໍ້ມູນຍັງໜ້ອຍເກີນທີ່ຈະສະຫຼຸບ"]

    return {
        "punches": n,
        "unique_points": len(uniq),
        "unique_ratio": round(unique_ratio, 2),
        "spread_m": round(spread, 1),
        "median_accuracy_m": round(med_acc, 1) if med_acc is not None else None,
        "zero_accuracy_count": zero_acc,
        "flagged_count": flagged,
        "score": min(score, 100),
        "verdict": verdict,
        "reasons": reasons,
    }


@router.get("")
def audit(days: int = Query(30, ge=7, le=180),
          db: Session = Depends(get_db),
          owner: ShopOwner = Depends(_get_owner)):
    from datetime import timedelta
    from ..core.timeutil import lao_now

    since = lao_now().date() - timedelta(days=days)
    staff = db.scalars(select(Staff).where(Staff.owner_id == owner.id)).all()

    results, coord_owners = [], {}
    for s in staff:
        rows = db.scalars(select(Attendance).where(
            Attendance.staff_id == s.id, Attendance.work_date >= since
        ).order_by(Attendance.clock_in_at.desc())).all()

        a = _analyse(rows)
        a.update({"staff_id": s.id, "staff_name": s.name, "active": bool(s.active)})
        results.append(a)

        for r in rows:
            if r.in_lat is not None:
                coord_owners.setdefault(_key(r.in_lat, r.in_lng), set()).add(s.id)

    # ພິກັດດຽວກັນເປັນະເປັນຂ້າມຄົນ = ຕັ້ງຄ່າປອມຮ່ວມກັນ
    shared = {sid for owners in coord_owners.values() if len(owners) > 1
              for sid in owners}
    for r in results:
        if r["staff_id"] in shared and r["punches"]:
            r["reasons"].append("ໃຊ້ພິກັດຊ້ຳກັນເປັນະເປັນກັບພະນັກງານຄົນອື່ນ")
            r["score"] = min(r["score"] + 35, 100)
            if r["verdict"] not in ("insufficient", "no_data"):
                r["verdict"] = "high" if r["score"] >= 60 else "medium"

    order = {"high": 0, "medium": 1, "low": 2, "insufficient": 3, "no_data": 4}
    results.sort(key=lambda x: (order.get(x["verdict"], 9), -x["score"]))

    return {
        "days": days,
        "checked": len(results),
        "high_risk": sum(1 for r in results if r["verdict"] == "high"),
        "items": results,
    }


@router.get("/{staff_id}/points")
def points(staff_id: int, days: int = Query(30, ge=7, le=180),
           db: Session = Depends(get_db),
           owner: ShopOwner = Depends(_get_owner)):
    """ພິກັດດິບແຕ່ລະຄັ້ງ ໃຫ້ເຈົ້າຂອງຮ້ານເບິ່ງເອງ."""
    from datetime import timedelta
    from ..core.timeutil import lao_now

    since = lao_now().date() - timedelta(days=days)
    rows = db.scalars(select(Attendance).where(
        Attendance.staff_id == staff_id, Attendance.owner_id == owner.id,
        Attendance.work_date >= since,
    ).order_by(Attendance.clock_in_at.desc()).limit(200)).all()

    return [{
        "date": r.work_date.isoformat(),
        "at": r.clock_in_at.isoformat() if r.clock_in_at else None,
        "lat": r.in_lat, "lng": r.in_lng,
        "accuracy_m": r.in_accuracy_m,
        "distance_m": round(r.in_distance_m) if r.in_distance_m is not None else None,
        "flags": r.flags or [],
    } for r in rows]
