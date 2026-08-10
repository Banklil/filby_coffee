"""ຮູບໂລໂກ້ຂອງແຕ່ລະຮ້ານ.

ເກັບ bytes ໄວ້ໃນ Postgres ບໍ່ແມ່ນໃນ UPLOAD_DIR ເພາະ filesystem ຂອງ Railway
ຫາຍທຸກຄັ້ງທີ່ redeploy — ຮູບທີ່ຮ້ານອັບໄວ້ຈະຫາຍໄປໂດຍບໍ່ຮູ້ຕົວ. ໂລໂກ້ໜຶ່ງຮ້ານ
ໜຶ່ງຮູບຂະໜາດນ້ອຍ ຈຶ່ງເກັບໃນຖານຂໍ້ມູນໄດ້ສະບາຍ ແລະ ບໍ່ຕ້ອງຕັ້ງ object storage.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile
from sqlalchemy.orm import Session

from ..database import get_db
from ..models.shop_owner import ShopOwner
from ..routers.shop_auth import _get_owner

router = APIRouter(prefix="/api/shop", tags=["shop-owner"])

MAX_BYTES = 2 * 1024 * 1024      # 2 MB — client ຫຍໍ້ມາແລ້ວ ບໍ່ຄວນເກີນນີ້


def _sniff(data: bytes) -> str | None:
    """ອ່ານຊະນິດຮູບຈາກ magic bytes.

    ບໍ່ໃຊ້ content_type ທີ່ client ສົ່ງມາ ເພາະປອມໄດ້ ແລະ client ບາງໂຕກໍ່ບໍ່ສົ່ງ.
    """
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return None


@router.post("/logo")
async def upload_logo(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    owner: ShopOwner = Depends(_get_owner),
):
    data = await file.read()
    if not data:
        raise HTTPException(400, "ໄຟລ໌ວ່າງເປົ່າ")
    if len(data) > MAX_BYTES:
        raise HTTPException(413, f"ຮູບໃຫຍ່ເກີນ {MAX_BYTES // 1024 // 1024} MB")

    mime = _sniff(data)
    if mime is None:
        raise HTTPException(400, "ຮັບສະເພາະຮູບ PNG, JPEG ຫຼື WebP")

    owner.logo_data = data
    owner.logo_mime = mime
    owner.logo_updated_at = datetime.now(timezone.utc)
    db.commit()

    return {"logo_url": f"/api/shop/{owner.id}/logo?v={int(owner.logo_updated_at.timestamp())}"}


@router.delete("/logo")
def delete_logo(db: Session = Depends(get_db),
                owner: ShopOwner = Depends(_get_owner)):
    owner.logo_data = None
    owner.logo_mime = None
    owner.logo_updated_at = None
    db.commit()
    return {"logo_url": None}


@router.get("/{owner_id}/logo")
def get_logo(owner_id: int, db: Session = Depends(get_db)):
    """ເປີດໃຫ້ອ່ານໄດ້ໂດຍບໍ່ຕ້ອງ login — ໂລໂກ້ຮ້ານບໍ່ແມ່ນຄວາມລັບ ແລະ ຕ້ອງໃຫ້
    <img> ໂຫຼດໄດ້ໂດຍກົງ. ບໍ່ມີຂໍ້ມູນສ່ວນຕົວຢູ່ໃນນັ້ນ."""
    owner = db.get(ShopOwner, owner_id)
    if not owner or not owner.logo_data:
        raise HTTPException(404, "ບໍ່ມີໂລໂກ້")
    return Response(
        content=bytes(owner.logo_data),
        media_type=owner.logo_mime or "image/jpeg",
        headers={"Cache-Control": "public, max-age=86400"},
    )
