#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Mount is /src = discourse/. Copy seed into container workspace via stdin.
docker exec -i -u discourse:discourse -w /src \
  -e RAILS_ENV=development \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  discourse_dev bundle exec rails runner "$(cat "${ROOT}/config/seed_forozeekr.rb")"
