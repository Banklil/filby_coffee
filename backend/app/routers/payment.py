"""
Payment settings router.
- GET  /api/payment/qr          → public, returns QR image URL
- POST /api/payment/qr          → admin uploads company QR code
- GET  /api/payment/pending     → admin: orders waiting for QR payment confirmation
- POST /api/payment/confirm/{id}→ admin: mark order as paid / confirmed
"""

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from sqlalchemy.orm import Session
import os

from ..database import get_db
from ..core.deps import get_current_user
from ..models.admin import Admin
from ..models.bean_order import BeanOrder
from ..models.shop_owner import ShopOwner
from ..config import settings

router = APIRouter(prefix="/api/payment", tags=["payment"])

_QR_NAMES = ["company_qr.png", "company_qr.jpg", "company_qr.jpeg"]


def _qr_path() -> str | None:
    for name in _QR_NAMES:
        p = os.path.join(settings.UPLOAD_DIR, name)
        if os.path.exists(p):
            return p
    return None


def _qr_filename() -> str | None:
    for name in _QR_NAMES:
        p = os.path.join(settings.UPLOAD_DIR, name)
        if os.path.exists(p):
            return name
    return None


# ── Public ────────────────────────────────────────────────────────────────────

@router.get("/qr")
def get_qr(request: Request):
    """Returns the current company QR code URL (public)."""
    fname = _qr_filename()
    if fname:
        base = str(request.base_url).rstrip("/")
        return {"url": f"{base}/uploads/{fname}", "exists": True}
    return {"url": None, "exists": False}


# ── Admin: QR upload ──────────────────────────────────────────────────────────

@router.post("/qr")
async def upload_qr(
    file: UploadFile = File(...),
    current_user: Admin = Depends(get_current_user),
):
    """Admin: upload or replace company QR code image."""
    allowed = {"image/png", "image/jpeg", "image/jpg"}
    if file.content_type not in allowed:
        raise HTTPException(400, "ຮູບຕ້ອງເປັນ PNG ຫຼື JPEG")

    content = await file.read()
    if len(content) > settings.MAX_UPLOAD_SIZE:
        mb = settings.MAX_UPLOAD_SIZE // (1024 * 1024)
        raise HTTPException(400, f"ຮູບໃຫຍ່ເກີນ {mb} MB")

    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

    # Remove old QR files
    for name in _QR_NAMES:
        old = os.path.join(settings.UPLOAD_DIR, name)
        if os.path.exists(old):
            os.remove(old)

    ext = "png" if file.content_type == "image/png" else "jpg"
    save_path = os.path.join(settings.UPLOAD_DIR, f"company_qr.{ext}")
    with open(save_path, "wb") as f:
        f.write(content)

    return {"message": "ອັບໂຫລດ QR ສຳເລັດ", "filename": f"company_qr.{ext}"}


@router.delete("/qr")
def delete_qr(current_user: Admin = Depends(get_current_user)):
    """Admin: remove company QR code."""
    removed = False
    for name in _QR_NAMES:
        p = os.path.join(settings.UPLOAD_DIR, name)
        if os.path.exists(p):
            os.remove(p)
            removed = True
    if not removed:
        raise HTTPException(404, "ບໍ່ມີ QR code")
    return {"message": "ລຶບ QR ແລ້ວ"}


# ── Admin: pending payments ───────────────────────────────────────────────────

@router.get("/pending")
def get_pending(
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    """Admin: list orders waiting for QR payment confirmation."""
    orders = (
        db.query(BeanOrder)
        .filter(BeanOrder.status == "pending_payment")
        .order_by(BeanOrder.created_at.desc())
        .all()
    )
    result = []
    for o in orders:
        owner = db.query(ShopOwner).filter(ShopOwner.id == o.owner_id).first()
        result.append({
            "id":           o.id,
            "owner_name":   (owner.name      if owner else "—"),
            "shop_name":    (owner.shop_name if owner else "—"),
            "phone":        (owner.phone     if owner else "—"),
            "product_name": o.product_name,
            "quantity":     o.quantity,
            "unit":         o.unit or "kg",
            "total_price":  o.total_price,
            "note":         o.note or "",
            "created_at":   o.created_at.isoformat() if o.created_at else None,
        })
    return result


@router.post("/confirm/{order_id}")
def confirm_payment(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    """Admin: confirm QR payment received → move to processing."""
    order = db.query(BeanOrder).filter(BeanOrder.id == order_id).first()
    if not order:
        raise HTTPException(404, "ບໍ່ພົບ order")
    if order.status != "pending_payment":
        raise HTTPException(400, f"Order ສະຖານະ '{order.status}' ບໍ່ສາມາດຢືນຢັນໄດ້")
    order.status = "processing"
    db.commit()

    # Broadcast to admin sockets
    try:
        import asyncio
        from ..ws_manager import sio
        asyncio.create_task(
            sio.emit("payment_confirmed", {"order_id": order_id})
        )
    except Exception:
        pass

    return {"message": "ຢືນຢັນການຊຳລະແລ້ວ", "order_id": order_id}


@router.post("/reject/{order_id}")
def reject_payment(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    """Admin: reject / cancel a pending payment."""
    order = db.query(BeanOrder).filter(BeanOrder.id == order_id).first()
    if not order:
        raise HTTPException(404, "ບໍ່ພົບ order")
    order.status = "cancelled"
    db.commit()
    return {"message": "ຍົກເລີກ order ແລ້ວ", "order_id": order_id}
