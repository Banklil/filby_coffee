from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
import math
from datetime import datetime, timezone
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.application import Application
from ..models.shop import Shop
from ..models.audit_log import AuditLog
from ..schemas.application import ApplicationOut, ApproveRequest, RejectRequest, RequestInfoRequest, ApplicationListResponse

router = APIRouter(prefix="/api/applications", tags=["applications"])


@router.get("", response_model=ApplicationListResponse)
def list_applications(
    status: Optional[str] = "pending",
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: Admin = Depends(get_current_user),
):
    q = db.query(Application)
    if status and status != "all":
        q = q.filter(Application.status == status)
    total = q.count()
    items = q.order_by(Application.created_at.desc()).offset((page - 1) * limit).limit(limit).all()
    return ApplicationListResponse(items=items, total=total, page=page, limit=limit, pages=math.ceil(total / limit))


@router.get("/{app_id}", response_model=ApplicationOut)
def get_application(app_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(get_current_user)):
    app = db.query(Application).filter(Application.id == app_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສະໝັກ")
    return app


@router.post("/{app_id}/approve")
def approve_application(
    app_id: int, data: ApproveRequest,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin", "manager")),
):
    app = db.query(Application).filter(Application.id == app_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສະໝັກ")
    if app.status != "pending":
        raise HTTPException(status_code=400, detail="ຄຳສະໝັກນີ້ໄດ້ຮັບການດຳເນີນການແລ້ວ")

    shop_data = app.shop_data or {}
    is_merchant = bool(app.ref_id and app.ref_id.startswith("CA"))

    if is_merchant:
        # Merchant app — update existing shop, don't create duplicate
        owner_email = shop_data.get("owner_email")
        shop = db.query(Shop).filter(Shop.email == owner_email).first() if owner_email else None
        if shop:
            shop.credit_limit = data.approved_limit
            shop.status = "active"
        else:
            count = db.query(Shop).count()
            shop = Shop(
                shop_id=f"FC{count + 1:04d}",
                name=shop_data.get("name", "ບໍ່ລະບຸ"),
                owner_name=shop_data.get("name", "ບໍ່ລະບຸ"),
                phone=shop_data.get("phone", "—"),
                email=owner_email, province="ວຽງຈັນ",
                status="active", tier="bronze",
                credit_limit=data.approved_limit, credit_used=0,
            )
            db.add(shop)
            db.flush()
    else:
        count = db.query(Shop).count()
        shop_id_str = f"FB-SHOP-{count + 1:04d}"
        shop = Shop(
            shop_id=shop_id_str,
            name=shop_data.get("shopName", "ບໍ່ລະບຸ"),
            owner_name=shop_data.get("ownerName", "ບໍ່ລະບຸ"),
            phone=shop_data.get("phone", ""),
            email=shop_data.get("email"),
            province=shop_data.get("province", "ບໍ່ລະບຸ"),
            district=shop_data.get("district"),
            village=shop_data.get("village"),
            address_detail=shop_data.get("addressDetail"),
            years_in_biz=shop_data.get("yearsInBiz"),
            revenue_range=shop_data.get("revenueRange"),
            shop_types=shop_data.get("shopTypes"),
            staff_count=shop_data.get("staffCount"),
            credit_limit=data.approved_limit,
            credit_used=0, status="active",
        )
        db.add(shop)
        db.flush()

    app.status = "approved"
    app.reviewed_by = current_user.id
    app.reviewed_at = datetime.now(timezone.utc)
    app.review_notes = data.notes
    app.approved_limit = data.approved_limit
    app.shop_id = shop.id

    db.add(AuditLog(admin_id=current_user.id, action="application.approve", entity_type="application", entity_id=app_id))
    db.commit()

    # ── Sync back to merchant credit_applications_merchant ───────────
    if is_merchant:
        try:
            from ..models.credit_application import CreditApplication
            ca_id = int(app.ref_id[2:].lstrip("0") or "0")
            ca = db.query(CreditApplication).filter(CreditApplication.id == ca_id).first()
            if ca:
                ca.status = "approved"
                ca.reviewed_at = datetime.now(timezone.utc)
                db.commit()
                # Real-time notify to merchant WebSocket room
                import asyncio
                from ..ws_manager import notify_status_changed
                try:
                    loop = asyncio.get_running_loop()
                    loop.create_task(notify_status_changed(ca.id, "approved", ca.owner_id))
                except Exception:
                    pass
        except Exception as e:
            print(f"[WARN] merchant credit sync approve: {e}")

    return {"message": "ອະນຸມັດຄຳສະໝັກສຳເລັດ", "shop_id": shop.id, "shop_id_str": shop.shop_id}


@router.post("/{app_id}/reject")
def reject_application(
    app_id: int, data: RejectRequest,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin", "manager")),
):
    app = db.query(Application).filter(Application.id == app_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສະໝັກ")
    if app.status != "pending":
        raise HTTPException(status_code=400, detail="ຄຳສະໝັກນີ້ໄດ້ຮັບການດຳເນີນການແລ້ວ")
    is_merchant = bool(app.ref_id and app.ref_id.startswith("CA"))

    app.status = "rejected"
    app.reviewed_by = current_user.id
    app.reviewed_at = datetime.now(timezone.utc)
    app.review_notes = data.reason
    db.add(AuditLog(admin_id=current_user.id, action="application.reject", entity_type="application", entity_id=app_id))
    db.commit()

    # ── Sync back to merchant credit_applications_merchant ───────────
    if is_merchant:
        try:
            from ..models.credit_application import CreditApplication
            ca_id = int(app.ref_id[2:].lstrip("0") or "0")
            ca = db.query(CreditApplication).filter(CreditApplication.id == ca_id).first()
            if ca:
                ca.status = "rejected"
                ca.reviewer_note = data.reason
                ca.reviewed_at = datetime.now(timezone.utc)
                db.commit()
                import asyncio
                from ..ws_manager import notify_status_changed
                try:
                    loop = asyncio.get_running_loop()
                    loop.create_task(notify_status_changed(ca.id, "rejected", ca.owner_id))
                except Exception:
                    pass
        except Exception as e:
            print(f"[WARN] merchant credit sync reject: {e}")

    return {"message": "ປະຕິເສດຄຳສະໝັກແລ້ວ"}


@router.post("/{app_id}/request-info")
def request_info(
    app_id: int, data: RequestInfoRequest,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin", "manager")),
):
    app = db.query(Application).filter(Application.id == app_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຄຳສະໝັກ")
    db.add(AuditLog(admin_id=current_user.id, action="application.request_info", entity_type="application", entity_id=app_id, log_metadata={"message": data.message}))
    db.commit()
    return {"message": "ສົ່ງຂໍ້ຄວາມຂໍຂໍ້ມູນເພີ່ມເຕີມແລ້ວ"}
