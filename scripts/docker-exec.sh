#!/usr/bin/env bash
# docker exec without requiring a TTY (safe for agents / CI / non-interactive shells)
set -euo pipefail
exec docker exec \
  -u discourse:discourse \
  -w /src \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  -e RAILS_ENV="${RAILS_ENV:-development}" \
  -e RANDOM_PASSWORD="${RANDOM_PASSWORD:-}" \
  discourse_dev \
  "$@"
