from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from .config import settings
from .database import engine, Base
from . import models  # ensure all models are imported before create_all

from .routers import auth, dashboard, shops, applications, orders, credits, products, analytics, reports, settings as settings_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(">>> Connecting to database and creating tables...")
    try:
        Base.metadata.create_all(bind=engine)
        print(">>> Database ready")
    except Exception as e:
        print(f">>> DB warning: {e}")
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


@app.get("/")
def root():
    return {"service": "Filby Coffee Admin API", "version": "1.0.0", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
