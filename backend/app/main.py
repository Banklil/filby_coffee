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
from .routers import bean_orders, credit_apps, merchant_report, admin_stats, payment, notifications, shop_logo


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
                "ALTER TABLE bean_orders_merchant ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20)",
                "ALTER TABLE bean_orders_merchant ADD COLUMN IF NOT EXISTS phone VARCHAR(50)",
                "ALTER TABLE bean_orders_merchant ADD COLUMN IF NOT EXISTS delivery_address VARCHAR(500)",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS bean_balance_kg DOUBLE PRECISION DEFAULT 0",
                "ALTER TABLE bean_orders_merchant ADD COLUMN IF NOT EXISTS stock_credited BOOLEAN DEFAULT FALSE",
                # ── ລະບົບສິນເຊື່ອ: ມັດຈຳ, ສະຖານະ, ເງື່ອນໄຂຊຳລະ ──────────
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS owner_id INTEGER",
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS deposit_balance BIGINT NOT NULL DEFAULT 0",
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS credit_status VARCHAR(16) NOT NULL DEFAULT 'good'",
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS net_terms_days INTEGER NOT NULL DEFAULT 30",
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS unsecured_allowance BIGINT NOT NULL DEFAULT 0",
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS deposit_multiplier INTEGER NOT NULL DEFAULT 2",
                "ALTER TABLE shops ADD COLUMN IF NOT EXISTS last_review_at TIMESTAMPTZ",
                "CREATE INDEX IF NOT EXISTS ix_shops_owner_id ON shops (owner_id)",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS notifications_seen_at TIMESTAMPTZ",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS logo_data BYTEA",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS logo_mime VARCHAR(40)",
                "ALTER TABLE shop_owners ADD COLUMN IF NOT EXISTS logo_updated_at TIMESTAMPTZ",
                "CREATE TABLE IF NOT EXISTS schema_migrations ("
                "  key VARCHAR(120) PRIMARY KEY,"
                "  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW())",
            ]:
                conn.execute(text(stmt))
            conn.commit()
        print(">>> Column migrations applied")
    except Exception as e:
        print(f">>> Column migration warning: {e}")

    # ── Backfill ທີ່ຕ້ອງແລ່ນຄັ້ງດຽວຈິງໆ ───────────────────────────────
    # ຮ້ານທີ່ມີວົງເງິນຢູ່ກ່ອນລະບົບມັດຈຳ ຍັງບໍ່ໄດ້ວາງມັດຈຳ ຈຶ່ງໃຫ້ unsecured
    # allowance ເທົ່າວົງເງິນເດີມ ເພື່ອບໍ່ໃຫ້ສັ່ງເຄື່ອງບໍ່ໄດ້ກະທັນຫັນ.
    #
    # ຫ້າມໃຊ້ເງື່ອນໄຂແບບ "WHERE last_review_at IS NULL" — ມັນເປັນຈິງອີກທຸກເທື່ອ
    # ທີ່ມີຮ້ານໃໝ່ຖືກອະນຸມັດ ດັ່ງນັ້ນທຸກ restart ຈະຍົກເວັ້ນມັດຈຳໃຫ້ຮ້ານໃໝ່ໂດຍ
    # ອັດຕະໂນມັດ ຊຶ່ງທຳລາຍຫຼັກປະກັນທັງໝົດ. ໃຊ້ marker ໃນຕາຕະລາງແທນ.
    try:
        from sqlalchemy import text
        KEY = "backfill_unsecured_allowance_v1"
        with engine.connect() as conn:
            done = conn.execute(
                text("SELECT 1 FROM schema_migrations WHERE key = :k"), {"k": KEY}
            ).scalar()
            if done:
                print(">>> Backfill already applied, skipping")
            else:
                n = conn.execute(text(
                    "UPDATE shops SET unsecured_allowance = credit_limit, "
                    "last_review_at = NOW() WHERE credit_limit > 0"
                )).rowcount
                conn.execute(text(
                    "INSERT INTO schema_migrations (key) VALUES (:k) "
                    "ON CONFLICT (key) DO NOTHING"), {"k": KEY})
                conn.commit()
                print(f">>> Backfill applied to {n} shop(s)")
    except Exception as e:
        print(f">>> Column migration warning: {e}")

    # ຄິດດອກເບ້ຍ ແລະ ປັບສະຖານະສິນເຊື່ອ ວັນລະຄັ້ງ — ບໍ່ຕ້ອງມີ cron ພາຍນອກ
    from .jobs import scheduler as credit_scheduler
    credit_scheduler.start()

    yield

    await credit_scheduler.stop()


app = FastAPI(
    title="Filby Coffee Admin API",
    description="Admin dashboard API for Filby Coffee B2B BNPL service",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS: lock to the configured frontend origin(s) when FRONTEND_URL is set;
# otherwise stay permissive so same-origin / mobile / tunnel access keeps working.
_cors_origins = ["*"] if not settings.FRONTEND_URL else settings.cors_origins_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def _catch_all(request: Request, exc: Exception):
    import traceback
    # Full detail stays in the server logs; the client gets a generic message
    # so internal exception types / stack info are never exposed.
    traceback.print_exc()
    return JSONResponse(
        status_code=500,
        content={"detail": "ເກີດຂໍ້ຜິດພາດພາຍໃນລະບົບ"},
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
app.include_router(payment.router)
app.include_router(notifications.router)
app.include_router(shop_logo.router)

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
