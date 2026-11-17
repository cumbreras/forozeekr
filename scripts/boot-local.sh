#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEXEC="${ROOT}/scripts/docker-exec.sh"

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Colima: colima start --cpu 4 --memory 6 --disk 40"
  exit 1
fi

"${ROOT}/scripts/clone-discourse.sh"

if ! docker ps --format '{{.Names}}' | grep -qx discourse_dev; then
  if docker ps -a --format '{{.Names}}' | grep -qx discourse_dev; then
    docker start discourse_dev
  else
    # boot_dev pulls image + starts container; skip interactive --init
    # (bundle/pnpm via d/* need a TTY — we install below without -t)
    cd "${ROOT}/discourse"
    # Patch around TTY: start container only by invoking the docker run portion
    DATA_DIR="${ROOT}/discourse/data/postgres"
    mkdir -p "${DATA_DIR}"
    docker pull discourse/discourse_dev:release
    docker run -d \
      -p 127.0.0.1:8025:8025 \
      -p 127.0.0.1:3000:3000 \
      -p 127.0.0.1:9292:9292 \
      -p 127.0.0.1:9405:9405 \
      -v "${DATA_DIR}:/shared/postgres_data:delegated" \
      -v "${ROOT}/discourse:/src:delegated" \
      -e UNICORN_BIND_ALL=true \
      --hostname=discourse \
      --name=discourse_dev \
      --restart=always \
      discourse/discourse_dev:release /sbin/boot
  fi
fi

echo "Waiting for Postgres..."
for i in $(seq 1 60); do
  if docker exec -u postgres discourse_dev pg_isready -q 2>/dev/null; then
    break
  fi
  sleep 2
done

echo "bundle install..."
"${DEXEC}" bundle install

echo "pnpm install..."
"${DEXEC}" pnpm install

echo "db create/migrate..."
"${DEXEC}" bundle exec rake db:create || true
"${DEXEC}" bundle exec rake db:migrate

echo "Ensuring local admin..."
"${DEXEC}" bundle exec rails runner '
email = "admin@forozeekr.local"
u = User.find_by_email(email) || User.new(email: email)
u.username = UserNameSuggester.suggest(email) if u.new_record?
u.password = "ForoZeekrLocal1!"
u.active = true
u.save!
u.grant_admin!
u.change_trust_level!(1) if u.trust_level < 1
u.email_tokens.update_all(confirmed: true)
u.activate
puts "Admin: #{u.username} <#{u.email}>"
'

echo "Applying Spanish branding seed..."
"${ROOT}/scripts/seed-forozeekr.sh"

echo
echo "Boot complete. Start the app with: ./scripts/start-app.sh"
echo "URL: http://127.0.0.1:3000"
