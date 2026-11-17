#!/usr/bin/env bash
set -euo pipefail
if ! docker ps --format '{{.Names}}' | grep -qx discourse_dev; then
  echo "discourse_dev not running"
  exit 0
fi
docker exec discourse_dev bash -lc 'pkill -f "bin/rails s" || true; pkill -f "rolldown.mjs" || true; pkill -f "bin/pitchfork" || true; pkill -f "bin/dev" || true' || true
echo "App processes stopped (container still running)."
echo "To stop the container: cd discourse && ./bin/docker/shutdown_dev"
