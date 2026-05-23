from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from ..database import get_db
from ..core.security import decode_token
from ..models.admin import Admin

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> Admin:
    token = credentials.credentials
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="ໂທເຄັນບໍ່ຖືກຕ້ອງ")
    admin_id = payload.get("sub")
    if not admin_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="ໂທເຄັນບໍ່ຖືກຕ້ອງ")
    admin = db.query(Admin).filter(Admin.id == int(admin_id), Admin.active == True).first()
    if not admin:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="ບໍ່ພົບຜູ້ໃຊ້")
    return admin


def require_roles(*roles: str):
    def checker(current_user: Admin = Depends(get_current_user)) -> Admin:
        if current_user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ບໍ່ມີສິດເຂົ້າເຖິງ")
        return current_user
    return checker
