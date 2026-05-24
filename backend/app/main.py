from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from .config import settings
from .database import engine, Base
from . import models  # ensure all models are imported before create_all

from .routers import auth, dashboard, shops, applications, orders, credits, products, analytics, reports, settings as settings_router, prospects, shop_auth


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
    allow_origins=settings.cors_origins_list,
    allow_origin_regex=r"https://.*\.railway\.app",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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


@app.get("/")
def root():
    return {"service": "Filby Coffee Admin API", "version": "1.0.0", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
