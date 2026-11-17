# Foro Zeekr — Discourse setup

Spanish Zeekr owner community for **forozeekr.com**. Local/dev on `~/dev/zeekr-forum` (folder kept; GitHub repo **forozeekr**).

**GitHub (public):** https://github.com/cumbreras/forozeekr  
**Local preview:** http://127.0.0.1:3000/  
**IA research:** [forum-competitive-analysis.md](./forum-competitive-analysis.md)

## Current state (2026-11-17)

| Item | Status |
|------|--------|
| Runtime | Colima + Docker; `discourse_dev` arm64 image |
| Theme direction | **Horizon** (core) + **Foro Zeekr** theme component |
| Fonts | Inter (`SiteSetting` + Google Fonts in component) |
| Colors | Teal `#00B3A6` on graphite `#0B1218` (Zeekr.eu / analysis) |
| Locale | `default_locale=es`, `allow_user_locale=false` (forced ES in local) |
| Home | Categories + Latest; short car hero; ad slots reserved **off** (v1) |
| Admin (local) | `admin@forozeekr.local` / `ForoZeekrLocal1!` |

## Theme approach (Blizzard / Google AI–style)

Polished Discourse communities (Blizzard forums, discuss.ai.google.dev) almost always use:

1. **A modern base theme** (Horizon today) for layout/cards/sidebar chrome  
2. **A small theme component** for brand CSS, fonts, header/hero HTML, ad placeholders  
3. **Site settings** for Categories+Latest + sidebar category list — not 50 subforums  

**Recommendation (narrowed):**

| Choice | Why |
|--------|-----|
| **Primary: Horizon + Foro Zeekr component** | Closest to Blizzard/Google polish out of the box; component carries Inter, Zeekr colors, short model hero, reserved ad slots |
| **Fallback: Foundation + same component** | If you need heavier component/plugin CSS compatibility later |

Also installed as selectable previews (not default): **Air**, **Graceful**, **Mint**. Do **not** lock those in.

### Preview / toggle locally

- Default: http://127.0.0.1:3000/ (Horizon + Foro Zeekr)  
- Theme preview query: `?preview_theme_id=-2` (Horizon), `-1` (Foundation), `1` (Air), `4` (Graceful), `5` (Mint)  
- Logged-in: Preferences → Interface → Theme  
- Reinstall component after edits: `./scripts/install-forozeekr-theme.sh`  
- Component settings (Admin → Customize → Themes → Foro Zeekr): `show_hero` (default on), `show_ad_slots` (default **off** — research: zero ads v1)

## Local workflow

```bash
colima start --cpu 4 --memory 6 --disk 40
cd ~/dev/zeekr-forum
./scripts/boot-local.sh
./scripts/start-app.sh
./scripts/seed-forozeekr.sh            # Spanish IA + tags
./scripts/install-forozeekr-theme.sh   # Horizon + component
```

## IA aligned with competitive analysis

**Intent categories** (≤10–12) + **model tags** (no board explosion):

| Category | Notes |
|----------|--------|
| Bienvenida y reglas | Intros + normas; independent-club tone |
| Modelos Zeekr | Require model tag |
| Compra, pedidos y entrega | Wartezimmer threads per model |
| Carga y autonomía | |
| Software, app y OTA | |
| Taller, garantía y seguros | |
| Accesorios y mods | |
| Encuentros España | CCAA tags later |
| Clasificados | Particular↔particular |
| Off-topic | |

**Tags:** model `001` `7x` `x` `7gt` `009` · intent `entrega` `averia` `ota` `wallbox` `viaje` · Tag group **Modelo**.

**Evergreen:** “Pedidos y entregas España — Zeekr {MODEL}” in Compra for each model.

Removed English clutter: Site Feedback, General; Staff → Equipo (restricted); Uncategorized → Sin categoría.

Nav: `top_menu=categories|latest|new|hot`; sidebar `default_navigation_menu_categories` = Spanish intent cats.

## Branding / hero

- Short graphite hero: wordmark + one mission line + model chips (9X / 7X / 7GT / X / 001)  
- Not a tall dealer carousel  
- Ad leaderboard + rail markup present but **hidden** until `show_ad_slots=true`

Theme source: `~/dev/zeekr-forum/themes/forozeekr/`

## Production path (discourse_docker)

Prefer [discourse_docker](https://github.com/discourse/discourse_docker) on a Linux VPS. See `config/production/app.yml.example`. DNS/SMTP for forozeekr.com still user-owned; not required for local work.

## Next steps

1. Swap logo SVGs for final assets; optional real car stills in hero chips  
2. Enable Discourse Solved on technical categories; wiki FAQs  
3. Soft-require model tag in composer (category tag settings)  
4. VPS + DNS + SMTP for forozeekr.com  
5. Keep ads off until after launch traffic  
