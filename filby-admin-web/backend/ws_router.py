"""
Real-Time WebSocket router for Filby Coffee Admin Panel.
Integrates with the existing FastAPI backend (app/main.py).

Add to main.py:
    from .routers.ws_router import sio_app
    app.mount("/socket.io", sio_app)

Install:
    pip install python-socketio python-engineio
"""
import socketio
from typing import Any

# ── Socket.IO server ────────────────────────────────────────────────
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins="*",   # tighten in production
    logger=False,
    engineio_logger=False,
)

sio_app = socketio.ASGIApp(sio)

# Track connected admin sessions  { sid: user_id }
_admin_sessions: dict[str, int] = {}


# ── Connection lifecycle ────────────────────────────────────────────
@sio.event
async def connect(sid: str, environ: dict, auth: dict | None = None):
    token = (auth or {}).get("token", "")
    user  = await _verify_token(token)
    if not user:
        raise ConnectionRefusedError("unauthorized")
    await sio.save_session(sid, {"user_id": user["id"], "role": user["role"]})
    if user["role"] in ("admin", "super_admin"):
        _admin_sessions[sid] = user["id"]
        await sio.enter_room(sid, "admins")
    await sio.enter_room(sid, f"merchant_{user['id']}")
    print(f"[WS] connected sid={sid} user={user['id']} role={user['role']}")


@sio.event
async def disconnect(sid: str):
    _admin_sessions.pop(sid, None)
    print(f"[WS] disconnected sid={sid}")


# ── Public helpers (called from API route handlers) ─────────────────
async def notify_new_bean_order(order: dict[str, Any]) -> None:
    """
    Broadcast to ALL admin connections when a merchant places a bean order.
    Call this from your bean order creation endpoint.

    Example (in orders router):
        from ..ws_router import notify_new_bean_order
        await notify_new_bean_order(order.dict())
    """
    payload = {
        "id":           order.get("id"),
        "shop_name":    order.get("shop_name", ""),
        "product_name": order.get("product_name", ""),
        "quantity":     float(order.get("quantity", 0)),
        "total_price":  float(order.get("total_price", 0)),
        "created_at":   str(order.get("created_at", "")),
    }
    await sio.emit("new_bean_order", payload, room="admins")


async def notify_new_credit_application(app: dict[str, Any]) -> None:
    """
    Broadcast to admins when a credit application is submitted.
    Call from your credit application POST endpoint.
    """
    payload = {
        "application_id": app.get("id"),
        "applicant_name": app.get("full_name", ""),
        "amount":         float(app.get("amount", 0)),
        "status":         app.get("status", "pending"),
        "created_at":     str(app.get("created_at", "")),
    }
    await sio.emit("new_credit_application", payload, room="admins")


async def notify_status_changed(application_id: int, new_status: str, merchant_id: int) -> None:
    """
    Notify the specific merchant that their application status changed.
    """
    payload = {
        "application_id": application_id,
        "new_status":     new_status,
    }
    # Notify the merchant's personal room
    await sio.emit("application_status_changed", payload, room=f"merchant_{merchant_id}")
    # Also push to admins for the audit log
    await sio.emit("application_status_changed", payload, room="admins")


# ── Internal helpers ────────────────────────────────────────────────
async def _verify_token(token: str) -> dict | None:
    """
    Validate JWT and return user dict or None.
    Reuses the existing FastAPI security helpers.
    """
    if not token:
        return None
    try:
        from app.core.security import decode_access_token
        from app.database import SessionLocal
        from app.models.shop import Shop

        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None

        db = SessionLocal()
        try:
            user = db.query(Shop).filter(Shop.id == int(user_id)).first()
            if not user:
                return None
            return {"id": user.id, "email": user.email, "role": getattr(user, "role", "merchant")}
        finally:
            db.close()
    except Exception:
        return None
