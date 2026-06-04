import sys
sys.path.insert(0, '/app')
from app.database import SessionLocal
from app.models.shop_owner import ShopOwner
from app.core.security import get_password_hash

db = SessionLocal()
existing = db.query(ShopOwner).filter(ShopOwner.email == 'bankhot2255@gmail.com').first()
if existing:
    print("Account already exists, ID:", existing.id)
else:
    o = ShopOwner(
        email='bankhot2255@gmail.com',
        password_hash=get_password_hash('Bank4212'),
        shop_name='Filby coffee'
    )
    db.add(o)
    db.commit()
    db.refresh(o)
    print("Created, ID:", o.id)
db.close()
