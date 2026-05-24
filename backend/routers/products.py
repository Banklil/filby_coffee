from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from database import get_db
from models import Product, User
from deps import get_current_user

router = APIRouter()


class ProductCreate(BaseModel):
    name: str
    category: str = "ອື່ນໆ"
    emoji: str = "☕"
    price: int
    unit: str = "ກິໂລ"
    stock: float = 0.0
    low_stock_alert: float = 2.0


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    emoji: Optional[str] = None
    price: Optional[int] = None
    unit: Optional[str] = None
    stock: Optional[float] = None
    low_stock_alert: Optional[float] = None


class ProductResponse(BaseModel):
    id: int
    name: str
    category: str
    emoji: str
    price: int
    unit: str
    stock: float
    low_stock_alert: float

    class Config:
        from_attributes = True


@router.get("/", response_model=list[ProductResponse])
def list_products(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Product).filter(Product.user_id == current_user.id).all()


@router.get("/low-stock", response_model=list[ProductResponse])
def low_stock(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    products = db.query(Product).filter(Product.user_id == current_user.id).all()
    return [p for p in products if p.stock <= p.low_stock_alert]


@router.post("/", response_model=ProductResponse)
def create_product(body: ProductCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    product = Product(**body.model_dump(), user_id=current_user.id)
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.put("/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, body: ProductUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id, Product.user_id == current_user.id).first()
    if not product:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບສິນຄ້າ")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(product, field, value)
    db.commit()
    db.refresh(product)
    return product


@router.delete("/{product_id}")
def delete_product(product_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id, Product.user_id == current_user.id).first()
    if not product:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບສິນຄ້າ")
    db.delete(product)
    db.commit()
    return {"ok": True}
