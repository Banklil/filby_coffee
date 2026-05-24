#!/bin/sh

echo "=== Filby Coffee Backend Starting ==="

if [ "$SKIP_SEED" != "true" ]; then
    echo ">>> Running seed data in background..."
    python seed.py &
fi

echo ">>> Testing app import..."
python -c "from app.main import app; print('>>> App import OK')" 2>&1
if [ $? -ne 0 ]; then
    echo ">>> IMPORT FAILED - check errors above"
    exit 1
fi

echo ">>> Starting API server on port ${PORT:-8000}"
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}" --log-level info 2>&1
