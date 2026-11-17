# Foro Zeekr (`forozeekr.com`)

Local Discourse setup for the Spanish Zeekr owner community.

**Public repo:** https://github.com/cumbreras/forozeekr

## Prerequisites (this Mac)

- Homebrew
- Colima + Docker CLI (`brew install colima docker docker-compose docker-buildx`)
- ~6 GB RAM allocated to Colima for a comfortable Discourse boot

## Quick start (local /dev)

```bash
# 1) Docker runtime
colima start --cpu 4 --memory 6 --disk 40

# 2) Clone Discourse (gitignored) if missing
./scripts/clone-discourse.sh

# 3) Boot container + deps + DB seed (Spanish + branding)
./scripts/boot-local.sh

# 4) Start app processes (Rails + frontend bundler)
./scripts/start-app.sh
```

Open **http://127.0.0.1:3000**

Default local admin (dev only):

- Email: `admin@forozeekr.local`
- Password: `ForoZeekrLocal1!`

MailHog (optional): `./discourse/bin/docker/mailhog` → http://127.0.0.1:8025

Stop processes: `./scripts/stop-app.sh`  
Stop container: `cd discourse && ./bin/docker/shutdown_dev`

## Repo layout

| Path | Purpose |
|------|---------|
| `scripts/` | Local boot / seed / start helpers |
| `config/` | Site settings + Spanish category seed (re-runnable) |
| `themes/forozeekr/` | Theme component placeholders (logo, SCSS, about) |
| `discourse/` | Upstream Discourse clone (local only, gitignored) |

## Production

Production should use official [discourse_docker](https://github.com/discourse/discourse_docker) on a VPS with DNS + SMTP for `forozeekr.com`. See Project docs (`docs/discourse-setup.md`) for DNS/email prerequisites and the promotion path from this local stack.
