"""ລາຍຮັບ-ລາຍຈ່າຍທີ່ຮ້ານບັນທຶກເອງ."""
from datetime import date, timedelta
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..core.timeutil import lao_now
from ..database import get_db
from ..models.shop_entry import ShopEntry
from ..models.shop_owner import ShopOwner
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/shop/entries", tags=["shop-entries"])

# ໝວດທີ່ຮ້ານກາເຟໃຊ້ຈິງ. ບໍ່ມີ "ເມັດກາເຟ" ແລະ "ຂາຍໜ້າຮ້ານ" ໂດຍເຈດຕະນາ —
# ສອງອັນນັ້ນມາຈາກ POS ແລະ ຄຳສັ່ງຊື້ອັດຕະໂນມັດ ຈະນັບຊ້ຳ.
CATEGORIES: dict[str, list[str]] = {
    "income": [
        "ຂາຍສົ່ງ",
        "ຮັບຈັດງານ / ອີເວັນ",
        "ຂາຍເຄື່ອງອື່ນ",
        "ເງິນທຶນເພີ່ມ",
        "ລາຍຮັບອື່ນໆ",
    ],
    "expense": [
        "ຄ່າເຊົ່າຮ້ານ",
        "ຄ່າແຮງງານ",
        "ຄ່ານ້ຳ - ໄຟຟ້າ",
        "ນົມ / ນ້ຳຕານ / ຊິຣັບ",
        "ແກ້ວ / ບັນຈຸພັນ",
        "ຄ່າຂົນສົ່ງ",
        "ຄ່າຊ່ອມແປງ ແລະ ອຸປະກອນ",
        "ອິນເຕີເນັດ / ໂທລະສັບ",
        "ການຕະຫຼາດ / ໂຄສະນາ",
        "ລາຍຈ່າຍອື່ນໆ",
    ],
}

MAX_AMOUNT = 1_000_000_000     # ກັນພິມຜິດເປັນຕົວເລກມະຫາສານ


class EntryIn(BaseModel):
    type: Literal["income", "expense"]
    category: str = Field(min_length=1, max_length=60)
    amount: int = Field(gt=0, le=MAX_AMOUNT)
    note: Optional[str] = Field(default=None, max_length=500)
    entry_date: Optional[date] = None


class EntryPatch(BaseModel):
    category: Optional[str] = Field(default=None, min_length=1, max_length=60)
    amount: Optional[int] = Field(default=None, gt=0, le=MAX_AMOUNT)
    note: Optional[str] = Field(default=None, max_length=500)
    entry_date: Optional[date] = None


def _out(e: ShopEntry) -> dict:
    return {
        "id": e.id,
        "type": e.type,
        "category": e.category,
        "amount": int(e.amount),
        "note": e.note,
        "entry_date": e.entry_date.isoformat() if e.entry_date else None,
        "created_at": e.created_at.isoformat() if e.created_at else None,
    }


def period_start(period: str) -> Optional[date]:
    today = lao_now().date()
    if period == "day":
        return today
    if period == "week":
        return today - timedelta(days=6)
    if period == "month":
        return today.replace(day=1)
    return None      # "all"


@router.get("/categories")
def categories():
    return CATEGORIES


@router.get("")
def list_entries(
    period: str = Query("month", pattern="^(day|week|month|all)$"),
    type: Optional[str] = Query(None, pattern="^(income|expense)$"),
    limit: int = Query(200, ge=1, le=500),
    db: Session = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    q = select(ShopEntry).where(ShopEntry.owner_id == owner.id)
    start = period_start(period)
    if start:
        q = q.where(ShopEntry.entry_date >= start)
    if type:
        q = q.where(ShopEntry.type == type)

    rows = db.scalars(
        q.order_by(ShopEntry.entry_date.desc(), ShopEntry.id.desc()).limit(limit)
    ).all()

    income = sum(int(r.amount) for r in rows if r.type == "income")
    expense = sum(int(r.amount) for r in rows if r.type == "expense")
    return {
        "items": [_out(r) for r in rows],
        "income": income,
        "expense": expense,
        "net": income - expense,
        "period": period,
    }


@router.post("", status_code=201)
def create_entry(body: EntryIn, db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    if body.category not in CATEGORIES[body.type]:
        raise HTTPException(400, "ໝວດນີ້ບໍ່ຢູ່ໃນລາຍການທີ່ອະນຸຍາດ")

    entry_date = body.entry_date or lao_now().date()
    if entry_date > lao_now().date():
        raise HTTPException(400, "ບັນທຶກລ່ວງໜ້າບໍ່ໄດ້")

    e = ShopEntry(
        owner_id=owner.id, type=body.type, category=body.category,
        amount=body.amount, note=body.note, entry_date=entry_date,
    )
    db.add(e)
    db.commit()
    db.refresh(e)
    return _out(e)


@router.patch("/{entry_id}")
def update_entry(entry_id: int, body: EntryPatch, db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    e = db.scalar(select(ShopEntry).where(
        ShopEntry.id == entry_id, ShopEntry.owner_id == owner.id))
    if not e:
        raise HTTPException(404, "ບໍ່ພົບລາຍການ")

    if body.category is not None:
        if body.category not in CATEGORIES[e.type]:
            raise HTTPException(400, "ໝວດນີ້ບໍ່ຢູ່ໃນລາຍການທີ່ອະນຸຍາດ")
        e.category = body.category
    if body.amount is not None:
        e.amount = body.amount
    if body.note is not None:
        e.note = body.note
    if body.entry_date is not None:
        if body.entry_date > lao_now().date():
            raise HTTPException(400, "ບັນທຶກລ່ວງໜ້າບໍ່ໄດ້")
        e.entry_date = body.entry_date

    db.commit()
    db.refresh(e)
    return _out(e)


@router.delete("/{entry_id}")
def delete_entry(entry_id: int, db: Session = Depends(get_db),
                 owner: ShopOwner = Depends(_get_owner)):
    e = db.scalar(select(ShopEntry).where(
        ShopEntry.id == entry_id, ShopEntry.owner_id == owner.id))
    if not e:
        raise HTTPException(404, "ບໍ່ພົບລາຍການ")
    db.delete(e)
    db.commit()
    return {"ok": True}


@router.get("/breakdown")
def breakdown(
    period: str = Query("month", pattern="^(day|week|month|all)$"),
    db: Session = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    """ລວມຍອດຕາມໝວດ — ໃຫ້ຮ້ານເຫັນວ່າເງິນຮົ່ວໄປທາງໃດ."""
    q = select(ShopEntry.type, ShopEntry.category,
               func.sum(ShopEntry.amount), func.count(ShopEntry.id)) \
        .where(ShopEntry.owner_id == owner.id)
    start = period_start(period)
    if start:
        q = q.where(ShopEntry.entry_date >= start)

    rows = db.execute(q.group_by(ShopEntry.type, ShopEntry.category)).all()
    out = {"income": [], "expense": []}
    for t, cat, total, n in rows:
        out[t].append({"category": cat, "total": int(total), "count": int(n)})
    for t in out:
        out[t].sort(key=lambda r: r["total"], reverse=True)
    return out
