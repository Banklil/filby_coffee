"""ຕົວຈັບເວລາພາຍໃນ — ແລ່ນ job ສິນເຊື່ອວັນລະຄັ້ງ ໂດຍບໍ່ຕ້ອງມີ cron ພາຍນອກ.

ເປັນຫຍັງບໍ່ໃຊ້ Railway cron: Railway cron ແລ່ນ start command ຂອງ service ຄືນໃໝ່
ຊຶ່ງຈະ restart API ທັງກ້ອນ ບໍ່ແມ່ນເອີ້ນ endpoint. ຈຶ່ງໃຊ້ asyncio task ໃນ
ຕົວ process ເອງ — ບໍ່ຕ້ອງເພີ່ມ dependency ແລະ ບໍ່ຕ້ອງເພີ່ມ service.

ປອດໄພຕໍ່ການແລ່ນຊ້ຳ: ທຸກລາຍການໃນ job ຜູກກັບ idempotency_key ທີ່ມີວັນທີຢູ່ນຳ
ດັ່ງນັ້ນ restart ຫຼາຍເທື່ອໃນມື້ດຽວກໍ່ບໍ່ຄິດດອກຊ້ຳ.
"""
import asyncio
import os
from datetime import timedelta

from ..core.timeutil import lao_now

# ຊົ່ວໂມງ (ເວລາລາວ) ທີ່ຈະແລ່ນ — ຕອນເຊົ້າມືດ ຄົນໃຊ້ງານນ້ອຍ
RUN_AT_HOUR = int(os.getenv("CREDIT_JOB_HOUR", "1"))

_task: asyncio.Task | None = None


def _seconds_until_next_run() -> float:
    now = lao_now()
    target = now.replace(hour=RUN_AT_HOUR, minute=0, second=0, microsecond=0)
    if target <= now:
        target += timedelta(days=1)
    return (target - now).total_seconds()


def _run_once_sync() -> dict:
    """ແລ່ນ job ໃນ thread ຕ່າງຫາກ — SQLAlchemy ຢູ່ນີ້ເປັນ sync."""
    from ..database import SessionLocal
    from .credit_daily import run_daily

    db = SessionLocal()
    try:
        return run_daily(db)
    finally:
        db.close()


async def _loop() -> None:
    # ແລ່ນເທື່ອໜຶ່ງຕອນ boot ເພື່ອຕາມເກັບມື້ທີ່ພາດໄປ (ເຊັ່ນ service ລົ້ມຄ້າງຄືນ)
    await asyncio.sleep(20)          # ລໍໃຫ້ຕາຕະລາງ ແລະ migration ພ້ອມກ່ອນ
    while True:
        try:
            stats = await asyncio.to_thread(_run_once_sync)
            print(f">>> credit job: {stats}")
        except asyncio.CancelledError:
            raise
        except Exception as e:
            # ຢ່າໃຫ້ຄວາມຜິດພາດມື້ດຽວຂ້າ loop ຖິ້ມ — ມື້ໜ້າຄ່ອຍລອງໃໝ່
            print(f">>> credit job failed: {e!r}")

        try:
            await asyncio.sleep(_seconds_until_next_run())
        except asyncio.CancelledError:
            raise


def start() -> None:
    """ເອີ້ນຈາກ lifespan ຕອນ startup."""
    global _task
    if os.getenv("CREDIT_JOB_ENABLED", "true").lower() in ("false", "0", "no"):
        print(">>> Credit daily job disabled by CREDIT_JOB_ENABLED")
        return
    if _task and not _task.done():
        return
    _task = asyncio.create_task(_loop())
    print(f">>> Credit daily job scheduled for {RUN_AT_HOUR:02d}:00 Asia/Vientiane")


async def stop() -> None:
    """ເອີ້ນຈາກ lifespan ຕອນ shutdown."""
    global _task
    if not _task:
        return
    _task.cancel()
    try:
        await _task
    except (asyncio.CancelledError, Exception):
        pass
    _task = None
