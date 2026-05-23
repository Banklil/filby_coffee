#!/bin/sh
set -e

echo "=== Filby Coffee Backend Starting ==="

# Run seed on first deploy (creates tables + sample data)
# Set SKIP_SEED=true in Railway variables to skip after first time
if [ "$SKIP_SEED" != "true" ]; then
    echo ">>> Running seed data..."
    python seed.py || echo ">>> Seed already ran or failed (continuing)"
fi

echo ">>> Starting API server on port ${PORT:-8000}"
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
