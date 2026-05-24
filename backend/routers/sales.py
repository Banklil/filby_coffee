from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from database import get_db
from models import Sale, SaleItem, Product, User
from deps import get_current_user

router = APIRouter()


class SaleItemIn(BaseModel):
    product_id: int
    product_name: str
    quantity: float
    price: int


class SaleCreate(BaseModel):
    items: list[SaleItemIn]
    note: str = ""


class SaleItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    quantity: float
    price: int

    class Config:
        from_attributes = True


class SaleResponse(BaseModel):
    id: int
    total: int
    note: str
    created_at: datetime
    items: list[SaleItemResponse]

    class Config:
        from_attributes = True


@router.get("/", response_model=list[SaleResponse])
def list_sales(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Sale)
        .filter(Sale.user_id == current_user.id)
        .order_by(Sale.created_at.desc())
        .limit(limit)
        .all()
    )


@router.get("/summary")
def sales_summary(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    now = datetime.utcnow()
    month_total = (
        db.query(func.sum(Sale.total))
        .filter(
            Sale.user_id == current_user.id,
            extract("year", Sale.created_at) == now.year,
            extract("month", Sale.created_at) == now.month,
        )
        .scalar()
        or 0
    )
    today_total = (
        db.query(func.sum(Sale.total))
        .filter(
            Sale.user_id == current_user.id,
            func.date(Sale.created_at) == now.date(),
        )
        .scalar()
        or 0
    )
    return {"month_total": month_total, "today_total": today_total}


@router.post("/", response_model=SaleResponse)
def create_sale(body: SaleCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not body.items:
        raise HTTPException(status_code=400, detail="ບໍ່ມີສິນຄ້າ")
    total = sum(item.price * item.quantity for item in body.items)
    sale = Sale(total=int(total), note=body.note, user_id=current_user.id)
    db.add(sale)
    db.flush()
    for item in body.items:
        db.add(SaleItem(
            sale_id=sale.id,
            product_id=item.product_id,
            product_name=item.product_name,
            quantity=item.quantity,
            price=item.price,
        ))
        product = db.query(Product).filter(Product.id == item.product_id, Product.user_id == current_user.id).first()
        if product:
            product.stock = max(0, product.stock - item.quantity)
    db.commit()
    db.refresh(sale)
    return sale
