# Foro Zeekr — Discourse setup

Spanish Zeekr community forum targeting **forozeekr.com**. Local/dev-first on the Mac checkout `~/dev/zeekr-forum`.

## Current state (2026-11-17)

| Item | Status |
|------|--------|
| Repo `~/dev/zeekr-forum` | Was empty (only `.git` / `.endloop`); now has scripts, seed, theme placeholders |
| Runtime | Colima + Docker CLI (Homebrew); no Docker Desktop required |
| Local Discourse | Official `discourse/discourse_dev:release` (**arm64** works on Apple Silicon) |
| URL | **http://127.0.0.1:3000** (Rails + rolldown frontend) |
| Locale | `default_locale=es` |
| Branding | Title **Foro Zeekr**, teal/graphite color scheme, logo SVG placeholders |
| Admin (local only) | `admin@forozeekr.local` / `ForoZeekrLocal1!` |

Upstream Discourse source lives at `~/dev/zeekr-forum/discourse/` (**gitignored** — clone via `./scripts/clone-discourse.sh`).

## Local workflow

```bash
colima start --cpu 4 --memory 6 --disk 40
cd ~/dev/zeekr-forum
./scripts/boot-local.sh    # container + gems/pnpm + DB + Spanish seed
./scripts/start-app.sh     # Rails :3000 + frontend bundler
./scripts/stop-app.sh      # stop app processes; keep container
# optional: cd discourse && ./bin/docker/shutdown_dev
```

Ports published on localhost:

| Port | Service |
|------|---------|
| 3000 | Discourse web |
| 8025 | MailHog (when started) |
| 9292 / 9405 | Dev extras |

Re-seed branding/categories anytime: `./scripts/seed-forozeekr.sh`

## Spanish localization defaults

Applied by `config/seed_forozeekr.rb`:

- `default_locale = es`
- User locale allowed; Accept-Language honored
- Categories: Bienvenida, Modelos Zeekr, Compra y entrega, Carga y autonomía, Software y OTA, Mantenimiento y taller, Accesorios y mods, Encuentros España, Off-topic
- Welcome topic in **Bienvenida**

## Branding (safe / no secrets)

- Site title: Foro Zeekr
- Accent: `#00B3A6` on graphite `#0B1218`
- Theme component scaffold: `themes/forozeekr/` (about.json, common.scss, logo SVG placeholders)
- Next: replace SVGs with final logos; install theme component in Admin → Customize → Themes (from git or zip)

## Production path (discourse_docker)

Prefer official [discourse_docker](https://github.com/discourse/discourse_docker) on a 64-bit Linux VPS (2 GB+ RAM). Local `discourse_dev` is for development only.

1. Point DNS (see below) once the host IP is known.
2. Install Docker on the VPS; clone `discourse_docker` to `/var/discourse`.
3. Copy `config/production/app.yml.example` ideas into `containers/app.yml` (`DISCOURSE_HOSTNAME=forozeekr.com`, `DISCOURSE_DEFAULT_LOCALE=es`, SMTP).
4. `./discourse-setup` or edit `app.yml` then `./launcher rebuild app`.
5. Create real admin; upload logos; re-apply Spanish categories (adapt seed for prod emails).
6. Enable Let’s Encrypt templates when DNS already resolves.

## Domain / DNS / email prerequisites (user configures later)

Live DNS is **not** required for local work.

### DNS (forozeekr.com)

| Record | Name | Value | Notes |
|--------|------|-------|-------|
| A (or AAAA) | `@` / `forozeekr.com` | VPS public IP | Apex |
| A (or CNAME) | `www` | same IP or `forozeekr.com` | Optional redirect |
| MX | `@` | Provider MX | Only if you receive mail at the domain |
| TXT | `@` | SPF | e.g. `v=spf1 include:… -all` |
| TXT | `._domainkey…` / provider DKIM | DKIM keys | From SMTP provider |
| TXT | `_dmarc` | DMARC policy | Start with `p=none` while testing |

Optional: CDN / proxy (Cloudflare etc.) — if used, configure SSL mode and Discourse `DISCOURSE_CDN_URL` carefully.

### Email (required for production invites / digests / 2FA)

Pick a transactional SMTP provider (examples: Amazon SES, Mailgun, Postmark, Resend). Configure in `app.yml`:

- `DISCOURSE_SMTP_ADDRESS` / `PORT` / `USER_NAME` / `PASSWORD`
- `DISCOURSE_SMTP_DOMAIN=forozeekr.com`
- `DISCOURSE_NOTIFICATION_EMAIL=noreply@forozeekr.com`

Verify the sending domain (SPF + DKIM) before inviting users. Local MailHog replaces SMTP in development.

### TLS

- Production: Let’s Encrypt via discourse_docker SSL templates once DNS points at the VPS.
- Local: HTTP only on `127.0.0.1` is fine.

## What not to do yet

- Do not put production SMTP passwords in this git repo.
- Do not require live DNS to continue theme/category/plugin work.
- Do not destroy `discourse/data/postgres` unless intentionally resetting local DB.

## Next concrete steps

1. Replace logo placeholders; install `themes/forozeekr` as a theme component.
2. Tune color scheme / welcome copy in Spanish with community feedback.
3. Provision VPS + DNS for `forozeekr.com`.
4. Stand up `discourse_docker` with SMTP; migrate settings from seed.
5. Optional: plugins (translate, calendar for encuentros, official SSO later).
