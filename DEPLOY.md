# ວິທີ Deploy ໄປ Railway

## ຮຽກຮ້ອງ
- [GitHub account](https://github.com)
- [Railway account](https://railway.app) (ສ້າງໂດຍ GitHub login)

---

## ຂັ້ນຕອນທີ 1 — Push ຂຶ້ນ GitHub

ເປີດ Terminal (PowerShell) ໃນ folder `filby-admin/`:

```powershell
# Init git
git init
git add .
git commit -m "initial commit: filby admin dashboard"

# ສ້າງ repo ໃໝ່ທີ່ github.com ກ່ອນ, ແລ້ວ:
git remote add origin https://github.com/YOUR_USERNAME/filby-admin.git
git branch -M main
git push -u origin main
```

---

## ຂັ້ນຕອນທີ 2 — ສ້າງ Project ໃນ Railway

1. ໄປທີ່ [railway.app](https://railway.app) → **New Project**
2. ເລືອກ **Deploy from GitHub repo**
3. ເລືອກ repo `filby-admin`
4. Railway ຈະສ້າງ 1 service ອັດຕະໂນມັດ → **ຍົກເລີກ/ບໍ່ໃຊ້ອັນນີ້ກ່ອນ**

---

## ຂັ້ນຕອນທີ 3 — ເພີ່ມ PostgreSQL Database

ໃນ Railway project:
1. ກົດ **+ Add Service** → **Database** → **PostgreSQL**
2. ລໍຖ້າ provision (~30 ວິ)
3. ໄປທີ່ PostgreSQL service → **Variables** tab
4. Copy `DATABASE_URL` ໄວ້ໃຊ້ໃນຂັ້ນຕອນຕໍ່ໄປ

---

## ຂັ້ນຕອນທີ 4 — Deploy Backend

1. ກົດ **+ Add Service** → **GitHub Repo** → `filby-admin`
2. ຕັ້ງຊື່ service: `filby-backend`
3. ຫຼັງຈາກສ້າງ → ໄປທີ່ **Settings** tab:
   - **Root Directory**: `backend`
   - **Watch Paths**: `backend/**`
4. ໄປທີ່ **Variables** tab → ເພີ່ມ:

```
DATABASE_URL        = <paste จาก PostgreSQL service>
SECRET_KEY          = <random string, ໃຊ້: python -c "import secrets; print(secrets.token_hex(32))">
ALGORITHM           = HS256
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS   = 7
CORS_ORIGINS        = ["http://localhost:5173"]
ENVIRONMENT         = production
```

5. ກົດ **Deploy** → ລໍຖ້າ build (~2-3 ນາທີ)
6. ໄປທີ່ **Settings** → **Networking** → **Generate Domain**
   - ຈະໄດ້ URL ເຊັ່ນ: `https://filby-backend-xxx.railway.app`
   - **ບັນທຶກ URL ນີ້ໄວ້!**

---

## ຂັ້ນຕອນທີ 5 — Run Seed Data

ຫຼັງ backend deploy ສຳເລັດ:

1. ໃນ `filby-backend` service → **Deploy** tab → ກົດ 3 dots → **Railway Shell**
   ຫຼື ໃຊ້ Railway CLI:

```bash
# ຕິດຕັ້ງ Railway CLI
npm install -g @railway/cli

# Login
railway login

# Run seed
railway run --service filby-backend python seed.py
```

ຫຼື ວິທີງ່າຍກວ່າ — ເພີ່ມ seed command ໃນ Variables ຊົ່ວຄາວ:
- Variables: `RUN_SEED=true`
- ສ້າງ `backend/startup.sh`:

```bash
#!/bin/sh
python seed.py 2>/dev/null || true
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

---

## ຂັ້ນຕອນທີ 6 — Deploy Frontend

1. ກົດ **+ Add Service** → **GitHub Repo** → `filby-admin`
2. ຕັ້ງຊື່ service: `filby-frontend`
3. **Settings** tab:
   - **Root Directory**: `frontend`
   - **Watch Paths**: `frontend/**`
4. **Variables** tab → ເພີ່ມ:

```
VITE_API_URL = https://filby-backend-xxx.railway.app/
```
> ⚠️ ສຳຄັນ: ຕ້ອງ ມີ `/` ທ້າຍ URL ເຊັ່ນ `https://xxx.railway.app/`

5. **Deploy** → ລໍຖ້າ build
6. **Settings** → **Networking** → **Generate Domain**
   - ຈະໄດ້ URL: `https://filby-frontend-xxx.railway.app`

---

## ຂັ້ນຕອນທີ 7 — Update CORS ໃນ Backend

ຫຼັງ frontend deploy ໄດ້ URL:

ກັບໄປທີ່ `filby-backend` → **Variables** → ອັບເດດ:
```
FRONTEND_URL = https://filby-frontend-xxx.railway.app
```

Backend ຈະ redeploy ອັດຕະໂນມັດ.

---

## ✅ ກວດສອບ

| URL | ຄາດຫວັງ |
|-----|---------|
| `https://filby-backend-xxx.railway.app/health` | `{"status":"ok"}` |
| `https://filby-backend-xxx.railway.app/docs` | Swagger UI |
| `https://filby-frontend-xxx.railway.app` | Login page |

---

## ທ່ານຈະ Login ດ້ວຍ:
```
Email:    admin@filby.la
Password: password123
```

---

## ❓ ແກ້ປັນຫາ

**Backend ຂຶ້ນ error "relation does not exist"**
→ Database ຍັງບໍ່ມີ tables. Seed script ຈະສ້າງ tables ອັດຕະໂນມັດ (Base.metadata.create_all). ລອງ run seed ໃໝ່.

**Frontend ຂຶ້ນ "Network Error"**
→ CORS ບໍ່ຖືກ. ກວດ `FRONTEND_URL` ໃນ backend variables ແລະ `VITE_API_URL` ໃນ frontend variables.

**Build ລົ້ມ "npm ci" error**
→ ລຶບ `package-lock.json` ຈາກ frontend, ໃຊ້ `npm install` ໃນ Dockerfile ແທນ.
