"""
/api/credit/applications — Credit application endpoints for merchant accounts.
Real-time: on POST, broadcasts new_credit_application to all admin sockets.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List

from ..database import get_db
from ..models.credit_application import CreditApplication
from ..models.shop_owner import ShopOwner
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/credit/applications", tags=["credit-applications"])


# ── Schemas ─────────────────────────────────────────────────────────
class CreditAppCreate(BaseModel):
    full_name:      str
    phone:          str
    id_card:        str
    business_name:  Optional[str]  = None
    amount:         float
    purpose:        str
    monthly_income: Optional[float] = None


class CreditAppOut(BaseModel):
    id:            int
    full_name:     str
    phone:         str
    id_card:       str
    business_name: Optional[str]
    amount:        float
    purpose:       str
    monthly_income:Optional[float]
    status:        str
    reviewer_note: Optional[str]
    created_at:    Optional[str]

    class Config:
        from_attributes = True


# ── Endpoints ────────────────────────────────────────────────────────
@router.get("", response_model=List[CreditAppOut])
def list_applications(
    db:    Session   = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    apps = (
        db.query(CreditApplication)
        .filter(CreditApplication.owner_id == owner.id)
        .order_by(CreditApplication.created_at.desc())
        .all()
    )
    return [_out(a) for a in apps]


@router.post("", response_model=CreditAppOut)
async def submit_application(
    body:  CreditAppCreate,
    db:    Session   = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    app = CreditApplication(
        owner_id       = owner.id,
        full_name      = body.full_name,
        phone          = body.phone,
        id_card        = body.id_card,
        business_name  = body.business_name,
        amount         = body.amount,
        purpose        = body.purpose,
        monthly_income = body.monthly_income,
        status         = "pending",
    )
    db.add(app)
    db.commit()
    db.refresh(app)

    # ── Real-time broadcast ──────────────────────────────────────────
    try:
        from ..ws_manager import notify_new_credit_application
        await notify_new_credit_application({
            "id":             app.id,
            "applicant_name": app.full_name,
            "amount":         app.amount,
            "status":         app.status,
            "created_at":     str(app.created_at),
        })
    except Exception:
        pass

    return _out(app)


@router.get("/{app_id}", response_model=CreditAppOut)
def get_application(
    app_id: int,
    db:     Session   = Depends(get_db),
    owner:  ShopOwner = Depends(_get_owner),
):
    app = db.query(CreditApplication).filter(
        CreditApplication.id == app_id,
        CreditApplication.owner_id == owner.id,
    ).first()
    if not app:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳຂໍ")
    return _out(app)


# ── Helper ───────────────────────────────────────────────────────────
def _out(a: CreditApplication) -> dict:
    return {
        "id":             a.id,
        "full_name":      a.full_name,
        "phone":          a.phone,
        "id_card":        a.id_card,
        "business_name":  a.business_name,
        "amount":         a.amount,
        "purpose":        a.purpose,
        "monthly_income": a.monthly_income,
        "status":         a.status,
        "reviewer_note":  a.reviewer_note,
        "created_at":     str(a.created_at) if a.created_at else None,
    }
