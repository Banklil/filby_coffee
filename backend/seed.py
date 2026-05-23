"""Seed script — run once: python seed.py"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from app.database import SessionLocal, engine, Base
from app import models
from app.models.admin import Admin
from app.models.shop import Shop
from app.models.application import Application
from app.models.order import Order
from app.models.transaction import Transaction
from app.models.product import Product
from app.core.security import get_password_hash
from datetime import datetime, timedelta, timezone, date
import random

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# --- Admins ---
if not db.query(Admin).filter(Admin.email == "admin@filby.la").first():
    db.add(Admin(email="admin@filby.la", password_hash=get_password_hash("password123"), name="Super Admin", role="super_admin"))
    db.add(Admin(email="manager@filby.la", password_hash=get_password_hash("password123"), name="ຜູ້ຈັດການ ສີດາ", role="manager"))
    db.add(Admin(email="support@filby.la", password_hash=get_password_hash("password123"), name="Support ດວງໃຈ", role="support"))
    db.add(Admin(email="accountant@filby.la", password_hash=get_password_hash("password123"), name="ນັກບັນຊີ ລັດທະນາ", role="accountant"))
    db.commit()

# --- Products ---
if not db.query(Product).first():
    products_data = [
        ("ກາເຟດຳ Bolaven Premium", "ໂບລາເວັນ", "arabica", 180000, "kg"),
        ("ກາເຟດຳ Paksong Select", "ປາກຊອງ", "arabica", 150000, "kg"),
        ("ກາເຟ Robusta Attapeu", "ອັດຕະປື", "robusta", 90000, "kg"),
        ("ກາເຟ Specialty Blend", "ໂບລາເວັນ", "special", 250000, "kg"),
        ("ກາເຟ Honey Process", "ໂບລາເວັນ", "special", 220000, "kg"),
        ("ເຄື່ອງບົດກາເຟ Breville", None, "equipment", 4500000, "ອັນ"),
        ("ເຄື່ອງຊົງ Espresso DeLonghi", None, "equipment", 8900000, "ອັນ"),
        ("ກ່ອງໃສ່ເມັດກາເຟ 1kg", None, "equipment", 25000, "ອັນ"),
        ("ຟິລເຕີ ກາເຟ V60 (100 ອັນ)", None, "equipment", 45000, "ກ່ອງ"),
        ("ເຄື່ອງຈ່າຍທຽວ POS Terminal", None, "equipment", 1200000, "ອັນ"),
    ]
    for name, origin, cat, price, unit in products_data:
        db.add(Product(name=name, origin=origin, category=cat, price=price, unit=unit, stock_qty=random.uniform(10, 100)))
    db.commit()

# --- Shops ---
provinces = ["ວຽງຈັນ", "ຫຼວງພະບາງ", "ສະຫວັນນະເຂດ", "ຈຳປາສັກ", "ຄຳມ່ວນ"]
tiers = ["bronze", "silver", "gold"]
shop_names = [
    ("ກາເຟ Morning Star", "ນາງ ສອນ ສີດາ"), ("Bolaven Café", "ທ້າວ ໄຊ ວົງ"), ("ຮ້ານກາເຟ ດາວ", "ນາງ ດາວ ແສງ"),
    ("Coffee Lab Vientiane", "ທ້າວ ດວງ ຄຳ"), ("Paksong Coffee House", "ນາງ ມາລີ ຈັນ"), ("The Blend", "ທ້າວ ສຸລິ ຍາ"),
    ("ກາເຟ ຮ່ມໄມ້", "ນາງ ອຸ່ນ ຈາລ"), ("Roast & Brew", "ທ້າວ ພູ ທອງ"), ("ກາເຟ ບ້ານ", "ນາງ ຄຳ ພູ"), ("Lao Coffee Co.", "ທ້າວ ສົມ ຊາດ"),
]

shops = []
if not db.query(Shop).first():
    for i, (sname, owner) in enumerate(shop_names):
        province = provinces[i % len(provinces)]
        tier = tiers[i % len(tiers)]
        limit = random.choice([5_000_000, 10_000_000, 20_000_000, 30_000_000])
        used = int(limit * random.uniform(0.2, 0.8))
        shop = Shop(
            shop_id=f"FB-SHOP-{i+1:04d}", name=sname, owner_name=owner,
            phone=f"020{random.randint(55000000,79999999)}", email=f"shop{i+1}@example.com",
            province=province, district="ເມືອງຈັນທະ", village="ບ້ານ ສີຫອມ",
            credit_limit=limit, credit_used=used, tier=tier, status="active",
            years_in_biz=random.choice(["1-3", "3-5", "5+"]),
            revenue_range=random.choice(["5-10M", "10-20M", "20-50M"]),
            shop_types=["dine-in", "takeaway"],
        )
        db.add(shop)
        shops.append(shop)
    db.commit()
    db.flush()
    for shop in shops:
        db.refresh(shop)
else:
    shops = db.query(Shop).all()

# --- Applications ---
if not db.query(Application).first():
    app_names = ["ຮ້ານກາເຟ ໃໝ່ 1", "Coffee New 2", "ກາເຟ ສົດ 3", "Brew Co 4", "ກາເຟ ໂຕ 5"]
    for i, aname in enumerate(app_names):
        ref_id = f"FB-APP-{i+1:04d}"
        status = "pending" if i < 3 else ("approved" if i == 3 else "rejected")
        db.add(Application(
            ref_id=ref_id,
            shop_data={"shopName": aname, "ownerName": f"ເຈົ້າຂອງ {i+1}", "phone": f"020555{i:05d}", "province": provinces[i % len(provinces)], "yearsInBiz": "1-3", "revenueRange": "5-10M"},
            credit_requested=random.choice([5_000_000, 10_000_000, 15_000_000]),
            purpose=random.choice(["beans", "equipment", "expansion"]),
            status=status,
        ))
    db.commit()

# --- Orders ---
if not db.query(Order).first() and shops:
    statuses = ["pending", "confirmed", "shipping", "delivered", "cancelled"]
    for i in range(20):
        shop = shops[i % len(shops)]
        status = statuses[i % len(statuses)]
        amount = random.randint(1, 5) * 1_000_000
        order = Order(
            order_id=f"FB-{2400+i}",
            shop_id=shop.id, amount=amount,
            items=[{"product_id": 1, "name": "ກາເຟດຳ Bolaven", "qty": random.randint(1, 10), "price": 180000}],
            shipping_address=f"{shop.village}, {shop.province}",
            status=status, payment_method=random.choice(["credit", "transfer"]),
            payment_due_date=date.today() + timedelta(days=random.randint(-5, 30)),
        )
        db.add(order)
    db.commit()
    db.flush()

    orders = db.query(Order).all()
    for order in orders:
        if order.status == "delivered":
            db.add(Transaction(shop_id=order.shop_id, type="credit_use", amount=order.amount, related_order_id=order.id, description=f"ຊື້ສິນຄ້າ order {order.order_id}"))
    db.commit()

    # Add some payments
    for shop in shops[:5]:
        db.add(Transaction(shop_id=shop.id, type="payment", amount=random.randint(1, 3) * 1_000_000, description="ຈ່າຍຄືນສິນເຊື່ອ"))
    db.commit()

db.close()
print("✅ Seed data created successfully!")
print("Admin accounts:")
print("  admin@filby.la / password123  (super_admin)")
print("  manager@filby.la / password123  (manager)")
print("  support@filby.la / password123  (support)")
print("  accountant@filby.la / password123  (accountant)")
