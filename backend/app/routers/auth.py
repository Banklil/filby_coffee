from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from ..database import get_db
from ..models.admin import Admin
from ..schemas.auth import LoginRequest, TokenResponse, RefreshRequest, AdminOut, PasswordResetRequest
from ..core.security import verify_password, create_access_token, create_refresh_token, decode_token
from ..core.deps import get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    admin = db.query(Admin).filter(Admin.email == request.email, Admin.active == True).first()
    if not admin or not verify_password(request.password, admin.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="ອີເມລ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ")
    admin.last_login = datetime.now(timezone.utc)
    db.commit()
    access_token = create_access_token({"sub": str(admin.id)})
    refresh_token = create_refresh_token({"sub": str(admin.id)})
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=AdminOut.model_validate(admin),
    )


@router.post("/refresh")
def refresh(request: RefreshRequest, db: Session = Depends(get_db)):
    payload = decode_token(request.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token ບໍ່ຖືກຕ້ອງ")
    admin_id = payload.get("sub")
    admin = db.query(Admin).filter(Admin.id == int(admin_id), Admin.active == True).first()
    if not admin:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="ບໍ່ພົບຜູ້ໃຊ້")
    return {"access_token": create_access_token({"sub": str(admin.id)}), "token_type": "bearer"}


@router.post("/logout")
def logout(current_user: Admin = Depends(get_current_user)):
    return {"message": "ອອກຈາກລະບົບສຳເລັດ"}


@router.get("/me", response_model=AdminOut)
def get_me(current_user: Admin = Depends(get_current_user)):
    return current_user


@router.post("/password-reset")
def password_reset(request: PasswordResetRequest, db: Session = Depends(get_db)):
    admin = db.query(Admin).filter(Admin.email == request.email).first()
    # Always return success for security — don't leak email existence
    return {"message": "ຖ້າອີເມລນີ້ຢູ່ໃນລະບົບ, ທ່ານຈະໄດ້ຮັບລິ້ງ reset ທາງອີເມລ"}
