# Filby Coffee Admin Dashboard

ລະບົບ Admin Dashboard ສຳລັບ Filby Coffee — ບໍລິການ B2B BNPL ສຳລັບຮ້ານກາເຟໃນລາວ.

## ໂຄງສ້າງໂປເຈັກ

```
filby-admin/
├── backend/          FastAPI + PostgreSQL
├── frontend/         Vue 3 + Vite + TailwindCSS
├── nginx/            Reverse proxy config
└── docker-compose.yml
```

## ການຕິດຕັ້ງ (Docker — ແນະນຳ)

### ຮຽກຮ້ອງ
- Docker Desktop
- Docker Compose

### ຂັ້ນຕອນ

```bash
# 1. Clone ໂປເຈັກ
git clone <repo-url> filby-admin
cd filby-admin

# 2. ສ້າງ .env file
cp backend/.env.example backend/.env

# 3. Start ທຸກ services
docker-compose up -d

# 4. ໃສ່ seed data (ຄັ້ງດຽວ)
docker exec filby_backend python seed.py

# 5. ເຂົ້າໃຊ້ງານ
#    Frontend:  http://localhost:80
#    API Docs:  http://localhost:8000/docs
#    Swagger:   http://localhost:8000/redoc
```

## ການຕິດຕັ້ງ (ພັດທະນາ — Manual)

### Backend

```bash
cd backend

# ສ້າງ virtual environment
python -m venv venv
venv\Scripts\activate   # Windows
source venv/bin/activate  # Mac/Linux

# ຕິດຕັ້ງ dependencies
pip install -r requirements.txt

# ຕັ້ງຄ່າ database
cp .env.example .env
# ແກ້ໄຂ .env ຕາມ config ຂອງທ່ານ

# Start backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd frontend

# ຕິດຕັ້ງ packages
npm install

# Start dev server
npm run dev
# → http://localhost:5173
```

### Database Seed

```bash
# ໃສ່ data ທົດສອບ
cd backend
python seed.py
```

## Admin Accounts

| Email | Password | Role |
|-------|----------|------|
| admin@filby.la | password123 | super_admin |
| manager@filby.la | password123 | manager |
| support@filby.la | password123 | support |
| accountant@filby.la | password123 | accountant |

## Features

| Feature | ສະຖານະ |
|---------|--------|
| 🔐 Authentication (JWT) | ✅ |
| 🏠 Dashboard + KPIs + Charts | ✅ |
| 🏪 Shop Management | ✅ |
| 📝 Credit Applications | ✅ |
| 📦 Orders Management | ✅ |
| 💰 Credits & Payments | ✅ |
| ☕ Product Catalog | ✅ |
| 📊 Analytics | ✅ |
| 📄 Reports (Excel/PDF) | ✅ |
| ⚙️ Settings & Audit Log | ✅ |

## API Docs

ເມື່ອ backend ໃຊ້ງານໄດ້, ເຂົ້າໄປທີ່:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Tech Stack

**Backend**: FastAPI · SQLAlchemy · PostgreSQL · JWT · Alembic

**Frontend**: Vue 3 · Vite · Pinia · TailwindCSS · ECharts · Lucide

**DevOps**: Docker · Nginx

## ຂໍ້ຄວນລະວັງ

> ⚠️ ສຳລັບ production ໃຫ້ປ່ຽນ `SECRET_KEY` ໃນ `.env` ໃຫ້ເປັນ random string ຍາວ ແລະ ປ່ຽນລະຫັດຜ່ານ admin ທັນທີ.
