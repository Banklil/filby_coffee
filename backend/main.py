from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import auth, products, sales, credit

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Filby Coffee API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(products.router, prefix="/products", tags=["products"])
app.include_router(sales.router, prefix="/sales", tags=["sales"])
app.include_router(credit.router, prefix="/credit", tags=["credit"])


@app.get("/")
def root():
    return {"status": "ok", "app": "Filby Coffee API"}


@app.get("/health")
def health():
    return {"status": "healthy"}
