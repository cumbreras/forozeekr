#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! docker ps --format '{{.Names}}' | grep -qx discourse_dev; then
  echo "discourse_dev is not running. Run ./scripts/boot-local.sh first."
  exit 1
fi

# Stop previous app processes if any
docker exec discourse_dev bash -lc 'pkill -f "bin/rails s" || true; pkill -f "rolldown.mjs" || true; pkill -f "bin/pitchfork" || true' >/dev/null 2>&1 || true
sleep 1

docker exec -d -u discourse:discourse -w /src \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  -e RAILS_ENV=development \
  -e UNICORN_BIND_ALL=true \
  discourse_dev bash -lc 'bundle exec rails s -b 0.0.0.0 -p 3000 > /tmp/rails.log 2>&1'

docker exec -d -u discourse:discourse -w /src/frontend/discourse \
  -e RAILS_ENV=development \
  discourse_dev bash -lc './rolldown.mjs > /tmp/ember.log 2>&1'

echo "Waiting for http://127.0.0.1:3000 ..."
for i in $(seq 1 40); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ || true)
  if [[ "${code}" == "200" || "${code}" == "302" ]]; then
    echo "Ready (HTTP ${code})"
    echo "Forum:   http://127.0.0.1:3000"
    echo "MailHog: http://127.0.0.1:8025 (start with discourse/bin/docker/mailhog if needed)"
    exit 0
  fi
  sleep 2
done

echo "Timed out waiting for Rails. Check: docker exec discourse_dev tail -100 /tmp/rails.log"
exit 1
