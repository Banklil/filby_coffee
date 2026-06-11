from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
import os

from .config import settings
from .database import engine, Base
from . import models  # ensure all models are imported before create_all

from .routers import auth, dashboard, shops, applications, orders, credits, products, analytics, reports, settings as settings_router, prospects, shop_auth, finance
from .routers import bean_orders, credit_apps, merchant_report, admin_stats


def _ensure_default_admin():
    from .database import SessionLocal
    from .models.admin import Admin
    from .core.security import get_password_hash
    db = SessionLocal()
    try:
        if not db.query(Admin).filter(Admin.email == "admin@filby.la").first():
            db.add(Admin(email="admin@filby.la", password_hash=get_password_hash("password123"), name="Super Admin", role="super_admin"))
            db.add(Admin(email="manager@filby.la", password_hash=get_password_hash("password123"), name="ຜູ້ຈັດການ ສີດາ", role="manager"))
            db.commit()
            print(">>> Default admins created")
    except Exception as e:
        print(f">>> Admin seed warning: {e}")
        db.rollback()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    import asyncio
    print(">>> Connecting to database and creating tables...")
    for attempt in range(5):
        try:
            Base.metadata.create_all(bind=engine)
            print(">>> Database ready")
            _ensure_default_admin()
            break
        except Exception as e:
            print(f">>> DB attempt {attempt + 1}/5 failed: {e}")
            if attempt < 4:
                await asyncio.sleep(5)
    # Safe column migrations for existing tables
    try:
        from sqlalchemy import text
        with engine.connect() as conn:
            for stmt in [
                "ALTER TABLE credit_applications_merchant ADD COLUMN IF NOT EXISTS approved_limit FLOAT",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS phone VARCHAR(30)",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS address VARCHAR(500)",
                "ALTER TABLE bean_orders_merchant ADD COLUMN IF NOT EXISTS unit VARCHAR(30)",
            ]:
                conn.execute(text(stmt))
            conn.commit()
        print(">>> Column migrations applied")
    except Exception as e:
        print(f">>> Column migration warning: {e}")
    yield


app = FastAPI(
    title="Filby Coffee Admin API",
    description="Admin dashboard API for Filby Coffee B2B BNPL service",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def _catch_all(request: Request, exc: Exception):
    import traceback
    traceback.print_exc()
    return JSONResponse(
        status_code=500,
        content={"detail": f"{type(exc).__name__}: {exc}"},
        headers={"Access-Control-Allow-Origin": "*"},
    )

# Static files for uploads
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

app.include_router(auth.router)
app.include_router(dashboard.router)
app.include_router(shops.router)
app.include_router(applications.router)
app.include_router(orders.router)
app.include_router(credits.router)
app.include_router(products.router)
app.include_router(analytics.router)
app.include_router(reports.router)
app.include_router(settings_router.router)
app.include_router(prospects.router)
app.include_router(shop_auth.router)
app.include_router(finance.router)
app.include_router(bean_orders.router)
app.include_router(credit_apps.router)
app.include_router(merchant_report.router)
app.include_router(admin_stats.router)

# ── Socket.IO real-time (optional — skipped if package missing) ──────
try:
    from .ws_manager import socket_asgi
    app.mount("/socket.io", socket_asgi)
    print(">>> Socket.IO mounted at /socket.io")
except Exception as _ws_err:
    print(f">>> Socket.IO skipped: {_ws_err}")


@app.get("/")
def root():
    return {"service": "Filby Coffee Admin API", "version": "1.0.0", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
