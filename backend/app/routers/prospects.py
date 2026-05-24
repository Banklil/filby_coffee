from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from typing import Optional
from ..database import get_db
from ..core.deps import get_current_user
from ..models.admin import Admin
from ..models.prospect import Prospect

router = APIRouter(prefix="/api/prospects", tags=["prospects"])


class ProspectIn(BaseModel):
    shop_name: str
    owner_name: str
    phone: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    province: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    daily_coffee_kg: float = 0
    weekly_coffee_kg: float = 0
    interest: str = "undecided"
    notes: Optional[str] = None


@router.get("")
def list_prospects(
    search: Optional[str] = None,
    interest: Optional[str] = None,
    province: Optional[str] = None,
    skip: int = 0,
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    q = db.query(Prospect)
    if search:
        q = q.filter(
            Prospect.shop_name.ilike(f"%{search}%") |
            Prospect.owner_name.ilike(f"%{search}%") |
            Prospect.phone.ilike(f"%{search}%")
        )
    if interest:
        q = q.filter(Prospect.interest == interest)
    if province:
        q = q.filter(Prospect.province == province)
    total = q.count()
    items = q.order_by(Prospect.created_at.desc()).offset(skip).limit(limit).all()
    return {
        "total": total,
        "items": [_serialize(p) for p in items],
    }


@router.post("")
def create_prospect(
    data: ProspectIn,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    p = Prospect(**data.model_dump(), created_by_id=current_user.id)
    db.add(p)
    db.commit()
    db.refresh(p)
    return _serialize(p)


@router.get("/analytics")
def analytics(
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    total = db.query(Prospect).count()
    interested = db.query(Prospect).filter(Prospect.interest == "interested").count()
    not_interested = db.query(Prospect).filter(Prospect.interest == "not_interested").count()
    undecided = db.query(Prospect).filter(Prospect.interest == "undecided").count()
    avg_daily = db.query(func.avg(Prospect.daily_coffee_kg)).scalar() or 0
    total_daily = db.query(func.sum(Prospect.daily_coffee_kg)).filter(Prospect.interest == "interested").scalar() or 0

    by_province = (
        db.query(Prospect.province, func.count(Prospect.id), Prospect.interest)
        .group_by(Prospect.province, Prospect.interest)
        .all()
    )
    province_map = {}
    for row in by_province:
        prov = row[0] or "ບໍ່ລະບຸ"
        if prov not in province_map:
            province_map[prov] = {"province": prov, "interested": 0, "not_interested": 0, "undecided": 0, "total": 0}
        province_map[prov][row[2]] = row[1]
        province_map[prov]["total"] += row[1]

    return {
        "total": total,
        "interested": interested,
        "not_interested": not_interested,
        "undecided": undecided,
        "avg_daily_kg": round(float(avg_daily), 2),
        "interested_total_daily_kg": round(float(total_daily), 2),
        "by_province": list(province_map.values()),
    }


@router.get("/{prospect_id}")
def get_prospect(prospect_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    p = db.query(Prospect).filter(Prospect.id == prospect_id).first()
    if not p:
        raise HTTPException(404, "Not found")
    return _serialize(p)


@router.put("/{prospect_id}")
def update_prospect(
    prospect_id: int,
    data: ProspectIn,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    p = db.query(Prospect).filter(Prospect.id == prospect_id).first()
    if not p:
        raise HTTPException(404, "Not found")
    for k, v in data.model_dump().items():
        setattr(p, k, v)
    db.commit()
    db.refresh(p)
    return _serialize(p)


@router.delete("/{prospect_id}")
def delete_prospect(prospect_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    p = db.query(Prospect).filter(Prospect.id == prospect_id).first()
    if not p:
        raise HTTPException(404, "Not found")
    db.delete(p)
    db.commit()
    return {"ok": True}


def _serialize(p: Prospect):
    return {
        "id": p.id,
        "shop_name": p.shop_name,
        "owner_name": p.owner_name,
        "phone": p.phone,
        "village": p.village,
        "district": p.district,
        "province": p.province,
        "lat": p.lat,
        "lng": p.lng,
        "daily_coffee_kg": p.daily_coffee_kg,
        "weekly_coffee_kg": p.weekly_coffee_kg,
        "interest": p.interest,
        "notes": p.notes,
        "created_at": p.created_at.isoformat() if p.created_at else None,
    }
