from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from ..database import get_db
from ..core.deps import get_current_user, require_roles
from ..models.admin import Admin
from ..models.audit_log import AuditLog
from ..schemas.admin import AdminCreate, AdminUpdate, AdminOut
from ..core.security import get_password_hash
from fastapi import HTTPException

router = APIRouter(prefix="/api", tags=["settings"])


@router.get("/admins")
def list_admins(db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin"))):
    return db.query(Admin).all()


@router.post("/admins", response_model=AdminOut)
def create_admin(data: AdminCreate, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin"))):
    if db.query(Admin).filter(Admin.email == data.email).first():
        raise HTTPException(status_code=400, detail="ອີເມລນີ້ມີຢູ່ແລ້ວ")
    admin = Admin(email=data.email, name=data.name, role=data.role, password_hash=get_password_hash(data.password))
    db.add(admin)
    db.commit()
    db.refresh(admin)
    return admin


@router.put("/admins/{admin_id}", response_model=AdminOut)
def update_admin(admin_id: int, data: AdminUpdate, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin"))):
    admin = db.query(Admin).filter(Admin.id == admin_id).first()
    if not admin:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຜູ້ໃຊ້")
    update_data = data.model_dump(exclude_none=True)
    if "password" in update_data:
        update_data["password_hash"] = get_password_hash(update_data.pop("password"))
    for k, v in update_data.items():
        setattr(admin, k, v)
    db.commit()
    db.refresh(admin)
    return admin


@router.delete("/admins/{admin_id}")
def delete_admin(admin_id: int, db: Session = Depends(get_db), current_user: Admin = Depends(require_roles("super_admin"))):
    admin = db.query(Admin).filter(Admin.id == admin_id).first()
    if not admin:
        raise HTTPException(status_code=404, detail="ບໍ່ພົບຜູ້ໃຊ້")
    if admin.id == current_user.id:
        raise HTTPException(status_code=400, detail="ບໍ່ສາມາດລຶບຕົນເອງໄດ້")
    admin.active = False
    db.commit()
    return {"message": "ລຶບຜູ້ໃຊ້ແລ້ວ"}


@router.get("/audit-logs")
def get_audit_logs(
    admin_id: Optional[int] = None,
    page: int = 1,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: Admin = Depends(require_roles("super_admin")),
):
    import math
    q = db.query(AuditLog)
    if admin_id:
        q = q.filter(AuditLog.admin_id == admin_id)
    total = q.count()
    items = q.order_by(AuditLog.created_at.desc()).offset((page-1)*limit).limit(limit).all()
    return {"items": [{"id": l.id, "admin_id": l.admin_id, "action": l.action, "entity_type": l.entity_type, "entity_id": l.entity_id, "created_at": l.created_at} for l in items], "total": total, "pages": math.ceil(total/limit)}
