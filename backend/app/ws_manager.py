"""
Socket.IO server for Filby Coffee real-time notifications.

Admins join room "admins".
Each merchant joins room "merchant_{owner_id}".

Public helpers (called from routers):
    await notify_new_bean_order(payload)
    await notify_new_credit_application(payload)
    await notify_status_changed(app_id, new_status, owner_id)
"""
import socketio
from typing import Any, Dict, Optional

sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins="*",
    logger=False,
    engineio_logger=False,
)

# Wrap as ASGI sub-app; mounted at /socket.io in main.py
socket_asgi = socketio.ASGIApp(sio, socketio_path="")


# ── Lifecycle ────────────────────────────────────────────────────────
@sio.event
async def connect(sid: str, environ: dict, auth: dict | None = None):
    user = await _verify_token((auth or {}).get("token", ""))
    if not user:
        raise ConnectionRefusedError("unauthorized")

    await sio.save_session(sid, user)

    if user.get("is_admin"):
        await sio.enter_room(sid, "admins")
    else:
        await sio.enter_room(sid, f"merchant_{user['id']}")

    print(f"[WS] connect sid={sid} user_id={user['id']} admin={user.get('is_admin')}")


@sio.event
async def disconnect(sid: str):
    print(f"[WS] disconnect sid={sid}")


# ── Broadcast helpers ────────────────────────────────────────────────
async def notify_new_bean_order(payload: Dict[str, Any]) -> None:
    await sio.emit("new_bean_order", payload, room="admins")


async def notify_new_credit_application(payload: Dict[str, Any]) -> None:
    await sio.emit("new_credit_application", payload, room="admins")


async def notify_status_changed(app_id: int, new_status: str, owner_id: int) -> None:
    data = {"application_id": app_id, "new_status": new_status}
    await sio.emit("application_status_changed", data, room=f"merchant_{owner_id}")
    await sio.emit("application_status_changed", data, room="admins")


# ── Token verification ───────────────────────────────────────────────
async def _verify_token(token: str) -> Optional[Dict]:
    if not token:
        return None
    try:
        from .core.security import decode_token
        from .database import SessionLocal
        from .models.shop_owner import ShopOwner
        from .models.admin import Admin

        payload = decode_token(token)
        if not payload:
            return None
        user_id = int(payload["sub"])

        db = SessionLocal()
        try:
            # Check admin first
            admin = db.query(Admin).filter(Admin.id == user_id).first()
            if admin:
                return {"id": admin.id, "email": admin.email, "is_admin": True}
            # Then shop owner
            owner = db.query(ShopOwner).filter(ShopOwner.id == user_id, ShopOwner.active == True).first()
            if owner:
                return {"id": owner.id, "email": owner.email, "is_admin": False}
        finally:
            db.close()
    except Exception as e:
        print(f"[WS] token verify error: {e}")
    return None
