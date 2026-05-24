from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from database import get_db
from models import CreditRecord, User
from deps import get_current_user

router = APIRouter()


class CreditCreate(BaseModel):
    customer_name: str
    amount: int
    note: str = ""


class CreditResponse(BaseModel):
    id: int
    customer_name: str
    amount: int
    paid: bool
    note: str
    created_at: datetime
    paid_at: Optional[datetime]

    class Config:
        from_attributes = True


@router.get("/", response_model=list[CreditResponse])
def list_credits(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return (
        db.query(CreditRecord)
        .filter(CreditRecord.user_id == current_user.id)
        .order_by(CreditRecord.created_at.desc())
        .all()
    )


@router.get("/summary")
def credit_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    records = db.query(CreditRecord).filter(CreditRecord.user_id == current_user.id, CreditRecord.paid == False).all()
    total_unpaid = sum(r.amount for r in records)
    return {"total_unpaid": total_unpaid, "count": len(records)}


@router.post("/", response_model=CreditResponse)
def create_credit(body: CreditCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    record = CreditRecord(**body.model_dump(), user_id=current_user.id)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.post("/{credit_id}/pay")
def mark_paid(credit_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    record = db.query(CreditRecord).filter(CreditRecord.id == credit_id, CreditRecord.user_id == current_user.id).first()
    if not record:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບລາຍການ")
    record.paid = True
    record.paid_at = datetime.utcnow()
    db.commit()
    return {"ok": True}


@router.delete("/{credit_id}")
def delete_credit(credit_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    record = db.query(CreditRecord).filter(CreditRecord.id == credit_id, CreditRecord.user_id == current_user.id).first()
    if not record:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບລາຍການ")
    db.delete(record)
    db.commit()
    return {"ok": True}
