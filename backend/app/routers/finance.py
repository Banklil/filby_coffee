from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from datetime import date, timedelta
from typing import Optional
from pydantic import BaseModel
from ..database import get_db
from ..core.deps import get_current_user
from ..core.timeutil import lao_now
from ..models.admin import Admin
from ..models.finance import FinanceEntry

router = APIRouter(prefix="/api/finance", tags=["finance"])

CATEGORIES = {
    "income": [
        "ລາຍຮັບຈາກການຂາຍ",
        "ດອກເບ້ຍ",
        "ຄ່ານາຍໜ້າ",
        "ຄ່າດຳເນີນການ",
        "ລາຍຮັບອື່ນໆ",
    ],
    "expense": [
        "ຄ່າເຊົ່າ",
        "ຄ່າຈ້າງ / ເງິນເດືອນ",
        "ຄ່ານ້ຳໄຟ",
        "ຄ່າຂົນສົ່ງ",
        "ຄ່າໂຄສະນາ",
        "ຄ່າຊ່ອມແຊມ",
        "ຄ່າອຸປະກອນ",
        "ລາຍຈ່າຍອື່ນໆ",
    ],
    "capital": [
        "ທຶນຈາກຜູ້ຖືຮຸ້ນ",
        "ເງິນກູ້ຢືມ",
        "ທຶນເພີ່ມ",
        "ທຶນອື່ນໆ",
    ],
}


class FinanceCreate(BaseModel):
    type: str
    category: str
    amount: int
    description: Optional[str] = None
    reference: Optional[str] = None
    entry_date: date


class FinanceUpdate(BaseModel):
    category: Optional[str] = None
    amount: Optional[int] = None
    description: Optional[str] = None
    reference: Optional[str] = None
    entry_date: Optional[date] = None


def entry_out(e: FinanceEntry):
    return {
        "id": e.id,
        "type": e.type,
        "category": e.category,
        "amount": e.amount,
        "description": e.description,
        "reference": e.reference,
        "entry_date": e.entry_date,
        "created_by": e.created_by,
        "created_at": e.created_at,
    }


@router.get("/categories")
def get_categories():
    return CATEGORIES


@router.get("/summary")
def get_summary(
    year: Optional[int] = None,
    month: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    now = lao_now()
    if date_from and date_to:
        month_start = date_from
        month_end = date_to + timedelta(days=1)
    else:
        y = year or now.year
        m = month or now.month
        month_start = date(y, m, 1)
        month_end = date(y + 1, 1, 1) if m == 12 else date(y, m + 1, 1)

    total_capital = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "capital"
    ).scalar() or 0

    total_income = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "income"
    ).scalar() or 0

    total_expense = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "expense"
    ).scalar() or 0

    month_income = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "income",
        FinanceEntry.entry_date >= month_start,
        FinanceEntry.entry_date < month_end,
    ).scalar() or 0

    month_expense = db.query(func.sum(FinanceEntry.amount)).filter(
        FinanceEntry.type == "expense",
        FinanceEntry.entry_date >= month_start,
        FinanceEntry.entry_date < month_end,
    ).scalar() or 0

    # Monthly breakdown for chart (last 12 months) — single grouped query
    # instead of 24 separate ones. entry_date is a plain date, so no tz work.
    window_year = now.year
    window_month = now.month - 11
    while window_month <= 0:
        window_month += 12
        window_year -= 1
    window_start = date(window_year, window_month, 1)

    grouped = (
        db.query(
            extract("year", FinanceEntry.entry_date).label("y"),
            extract("month", FinanceEntry.entry_date).label("m"),
            FinanceEntry.type,
            func.sum(FinanceEntry.amount).label("total"),
        )
        .filter(
            FinanceEntry.type.in_(["income", "expense"]),
            FinanceEntry.entry_date >= window_start,
        )
        .group_by("y", "m", FinanceEntry.type)
        .all()
    )
    bucket = {}
    for yy, mm, ttype, total in grouped:
        bucket.setdefault((int(yy), int(mm)), {})[ttype] = int(total or 0)

    monthly = []
    for i in range(11, -1, -1):
        mi = now.month - i
        yi = now.year
        while mi <= 0:
            mi += 12
            yi -= 1
        vals = bucket.get((yi, mi), {})
        inc = vals.get("income", 0)
        exp = vals.get("expense", 0)
        monthly.append({
            "month": f"{yi}-{mi:02d}",
            "label": f"{mi:02d}/{yi}",
            "income": inc,
            "expense": exp,
            "net": inc - exp,
        })

    return {
        "total_capital": int(total_capital),
        "total_income": int(total_income),
        "total_expense": int(total_expense),
        "total_net": int(total_income) - int(total_expense),
        "month_income": int(month_income),
        "month_expense": int(month_expense),
        "month_net": int(month_income) - int(month_expense),
        "monthly": monthly,
    }


@router.get("")
def list_entries(
    type: Optional[str] = None,
    year: Optional[int] = None,
    month: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    q = db.query(FinanceEntry)
    if type:
        q = q.filter(FinanceEntry.type == type)
    if date_from and date_to:
        q = q.filter(FinanceEntry.entry_date >= date_from, FinanceEntry.entry_date <= date_to)
    else:
        if year:
            q = q.filter(extract("year", FinanceEntry.entry_date) == year)
        if month:
            q = q.filter(extract("month", FinanceEntry.entry_date) == month)

    total = q.count()
    items = (
        q.order_by(FinanceEntry.entry_date.desc(), FinanceEntry.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
        .all()
    )
    return {
        "items": [entry_out(e) for e in items],
        "total": total,
        "page": page,
        "limit": limit,
        "pages": -(-total // limit),
    }


@router.post("")
def create_entry(
    data: FinanceCreate,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    if data.type not in ("income", "expense", "capital"):
        raise HTTPException(status_code=400, detail="type ຕ້ອງເປັນ income, expense, ຫຼື capital")
    entry = FinanceEntry(
        type=data.type,
        category=data.category,
        amount=data.amount,
        description=data.description,
        reference=data.reference,
        entry_date=data.entry_date,
        created_by=current_user.id,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry_out(entry)


@router.put("/{entry_id}")
def update_entry(
    entry_id: int,
    data: FinanceUpdate,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    e = db.query(FinanceEntry).filter(FinanceEntry.id == entry_id).first()
    if not e:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບລາຍການ")
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(e, k, v)
    db.commit()
    db.refresh(e)
    return entry_out(e)


@router.delete("/{entry_id}")
def delete_entry(
    entry_id: int,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    e = db.query(FinanceEntry).filter(FinanceEntry.id == entry_id).first()
    if not e:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບລາຍການ")
    db.delete(e)
    db.commit()
    return {"message": "ລຶບສຳເລັດ"}
