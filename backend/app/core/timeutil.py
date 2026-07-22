"""Lao-local time helpers.

The business operates in Laos (UTC+7). Transaction timestamps are stored as
timezone-aware `timestamptz`, so any day/month bucketing must be done in
Asia/Vientiane local time — otherwise records made in the early morning (Lao
time) fall into the previous UTC day/month.
"""
from datetime import datetime
from zoneinfo import ZoneInfo

LAO_TZ_NAME = "Asia/Vientiane"
LAO_TZ = ZoneInfo(LAO_TZ_NAME)


def lao_now() -> datetime:
    """Current time as a timezone-aware datetime in Asia/Vientiane."""
    return datetime.now(LAO_TZ)


def lao_month_start(dt: datetime | None = None) -> datetime:
    """First instant of the current Lao month (tz-aware)."""
    dt = dt or lao_now()
    return dt.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
