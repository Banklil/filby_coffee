from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional, List
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.product import Product
from ..schemas.product import ProductCreate, ProductUpdate, ProductOut, StockUpdate
import os, uuid
from ..config import settings

router = APIRouter(prefix="/api/products", tags=["products"])


@router.get("", response_model=List[ProductOut])
def list_products(db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    return db.query(Product).order_by(Product.category, Product.name).all()


@router.post("", response_model=ProductOut)
def create_product(
    name: str = Form(...),
    category: str = Form(...),
    price: int = Form(...),
    origin: Optional[str] = Form(None),
    unit: Optional[str] = Form(None),
    stock_qty: float = Form(0),
    image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin", "manager")),
):
    image_url = None
    if image:
        ext = image.filename.split(".")[-1] if image.filename else "jpg"
        filename = f"{uuid.uuid4()}.{ext}"
        upload_path = os.path.join(settings.UPLOAD_DIR, filename)
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        with open(upload_path, "wb") as f:
            f.write(image.file.read())
        image_url = f"/uploads/{filename}"

    product = Product(name=name, category=category, price=price, origin=origin, unit=unit, stock_qty=stock_qty, image_url=image_url)
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.put("/{product_id}", response_model=ProductOut)
def update_product(product_id: int, data: ProductUpdate, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບສິນຄ້າ")
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(product, k, v)
    db.commit()
    db.refresh(product)
    return product


@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin"))):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບສິນຄ້າ")
    product.active = False
    db.commit()
    return {"message": "ລຶບສິນຄ້າແລ້ວ"}


@router.post("/{product_id}/stock")
def update_stock(product_id: int, data: StockUpdate, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin", "manager"))):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບສິນຄ້າ")
    product.stock_qty = float(product.stock_qty) + data.delta
    db.commit()
    return {"message": "ອັບເດດສະຕັອກແລ້ວ", "stock_qty": float(product.stock_qty)}
