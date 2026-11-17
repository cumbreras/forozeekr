# Foro Zeekr — Discourse setup

Spanish Zeekr owner community for **forozeekr.com**. Local/dev on `~/dev/zeekr-forum` (folder kept; GitHub repo **forozeekr**).

**GitHub (public):** https://github.com/cumbreras/forozeekr  
**Local preview:** http://127.0.0.1:3000/  
**IA research:** [forum-competitive-analysis.md](./forum-competitive-analysis.md)

## Current state (2026-11-17)

| Item | Status |
|------|--------|
| Runtime | Colima + Docker; `discourse_dev` arm64 image |
| Baseline | Light **Horizon** (stock chrome usable without brand overlay) |
| Brand layer | Restrained **Foro Zeekr** component (v0.3) — few CSS overrides |
| Fonts | Inter |
| Colors | Light surfaces; teal `#00B3A6`; ink `#0B1218` (`Foro Zeekr Light` palette) |
| Logo | Foro Zeekr SVG wordmark (replaces Discourse sketch) |
| Home | Stock Horizon welcome **off**; short light photo hero (001 / 7X / X / 009) |
| Locale / IA | Spanish forced; intent categories + model tags; Clasificados |
| Ads | Reserved off (v1) |
| Admin (local) | `admin@forozeekr.local` / `ForoZeekrLocal1!` |

## Theme approach (quality over novelty)

1. Keep **Horizon light** as the usable baseline (detach component anytime if brand experiments go bad).  
2. Add a **thin** component only: logo, light palette tint, short photo hero, Inter.  
3. Avoid heavy dark “sticker” CSS on Discourse chrome.

**Primary:** Horizon + Foro Zeekr component. **Fallback:** plain Horizon (`ChildTheme` detach) or Foundation.

### Emergency: restore stock-quality Horizon

```bash
# Detach brand overlay in rails runner, or:
docker exec -u discourse discourse_dev bundle exec rails runner \
  'h=Theme.find_by(name:"Horizon"); ChildTheme.where(parent_theme_id:h.id).delete_all; h.update!(color_scheme_id:ColorScheme.find_by(name:"Horizon").id); h.set_default!'
```

### Preview / toggle

- Hard-refresh: http://127.0.0.1:3000/  
- Plain Horizon preview: `?preview_theme_id=-2` after detaching child, or temporarily disable component in Admin → Themes  
- Reinstall restrained brand: `./scripts/install-forozeekr-theme.sh`  
- Component setting: `show_hero` (default on)

### Assets to drop for production polish

| File | Path |
|------|------|
| Official logo (SVG/PNG light) | `themes/forozeekr/assets/logo.svg` then `./scripts/install-forozeekr-theme.sh` |
| Model stills 9X / 7GT (and better EU press of 001/7X/X/009) | `themes/forozeekr/assets/cars/zeekr-{9x,7gt,001,7x,x,009}.jpg` |
| Attribution | See `themes/forozeekr/assets/cars/ATTRIBUTION.json` (current: Wikimedia CC prototypes) |

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

## Branding / hero (v0.3 restrained)

- Light paper hero card; photo lineup (not letter tiles); labels under images  
- Header wordmark SVG; stock “¡Te damos la bienvenida…” banner disabled on Horizon  
- Minimal SCSS (header border, Inter, button radius, hero grid) — no dark full-page skin  
- Theme source: `~/dev/zeekr-forum/themes/forozeekr/`

## Production path (discourse_docker)

Prefer [discourse_docker](https://github.com/discourse/discourse_docker) on a Linux VPS. See `config/production/app.yml.example`. DNS/SMTP for forozeekr.com still user-owned; not required for local work.

## Next steps

1. Swap logo SVGs for final assets; optional real car stills in hero chips  
2. Enable Discourse Solved on technical categories; wiki FAQs  
3. Soft-require model tag in composer (category tag settings)  
4. VPS + DNS + SMTP for forozeekr.com  
5. Keep ads off until after launch traffic  
