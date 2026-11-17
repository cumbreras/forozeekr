# zeekr.eu visual parity — source tokens

Fetched from live https://www.zeekr.eu/ (and CSS under `/_nuxt/*.css`) for Foro Zeekr Discourse branding.  
Goal: maximize parity within Discourse; residual gaps must be hard platform limits only.

## 1. Color tokens (authoritative)

| Token | Value | Role on zeekr.eu |
|-------|-------|------------------|
| `--zk-primary-color` | `#24292B` | Primary graphite (buttons, ink, chrome) |
| `--zk-primary-color-hover` | `#353738` | Hover |
| `--zk-primary-color-active` | `#040505` | Active / pressed |
| `--zk-primary-1` … `7` | `#656A6B` → `#040505` | Graphite scale |
| `--zk-text-primary` | `#000000` | Body text |
| `--zk-text-secondary` | `#666666` | Secondary |
| `--zk-text-tertiary` | `#939393` | Tertiary / hints |
| `--zk-text-logo-light` | `#232323` | Logo on light |
| `--zk-text-logo-dark` | `#FFFBF3` | Logo on dark |
| `--primary-bg-color` | `#FFFFFF` | Primary surface |
| `--primary-bg-grey-color` | `#EBEBEB` | Grey wash |
| Wash / page greys | `#F5F5F5`, `#F7F7F7`, `#FAFAFA`, `#F5F5F7` | Page backgrounds |
| `--zk-success-color` | `#65C466` | Success |
| `--zk-error-color` | `#D2211E` | Error |
| `--zk-warning-color` | `#FAAD14` | Warning |
| Outline | `rgba(36,41,43,.12)` / `.2` | Borders / focus |

**Not brand-primary on zeekr.eu:** purple Discourse defaults, teal-as-primary, dark Horizon skins.  
Occasional marketing accent `#FF5841` appears in some modules — **do not** make it the forum primary; keep graphite/white like the core site chrome.

## 2. Typography

| Token | Value |
|-------|-------|
| Primary UI | `ZeekrText` |
| Medium | `ZeekrTextMedium` |
| Display | `ZeekrHeadline` |
| Fallbacks in CSS | `SF Pro Text`, `system-ui`, `-apple-system`, `Segoe UI`, `Roboto`, `Helvetica Neue`, `Arial` |

**Discourse stand-in:** Inter (loaded) with the same fallback stack. Proprietary Zeekr fonts are not redistributable — Inter is the closest licensed public match for UI.

Lettering cues: clean wordmarks, modest tracking, high weight contrast on headlines; logo mark is graphite `#232323` on light.

## 3. Radii & spacing

| Token | Value |
|-------|-------|
| `--zk-rd-s` | `4px` |
| `--zk-rd-m` | `8px` |
| `--zk-rd-l` | `12px` |
| Common control radius | `2px`–`4px` (sharp, not pill) |
| `--zk-pill` | `999px` (rare; chips only) |
| Spacing scale | `2,4,8,12,16,20,24,32,40,48,56,60,80,100,120,160` px |
| Content max | `--zeekr-maxer-content-width: 1296px` |

## 4. Header / nav structure (zeekr.eu)

Observed pattern:

1. **Light sticky header** on white / near-white  
2. **Left:** wordmark (graphite, not a colorful badge)  
3. **Center/left nav:** text links (Cars / Shop / Discover-style) — quiet weight, no chunky pills  
4. **Right:** utility actions (region, account, CTA)  
5. **Below or as page hero:** full-bleed media band (short on many interior pages; tall only on campaign landings)  
6. Borders: hairline `rgba(36,41,43,.12)` — little shadow

Discourse mapping:

| zeekr.eu | Discourse |
|----------|-----------|
| Wordmark left | `#site-logo` + SVG wordmark `FORO ZEEKR` |
| Primary nav | Sidebar category links + top_menu tabs (Categorías / Recientes / Nuevos / Top) |
| Utility right | Default header icons (search, user) — restyle only |
| Media band | Full-width short `.fz-hero-banner` under header (custom image drop) |

## 5. Buttons

- Primary: fill `#24292B`, text white, hover `#353738`, active `#040505`  
- Radius ~`2px`–`4px`  
- Weight semibold; slight letter-spacing  
- Not rounded-full; not teal/purple fills

## 6. Surfaces

- Page: light grey wash (`#F7F7F7` / `#F5F5F5`) or white  
- Cards/panels: white + 1px graphite-alpha border  
- Avoid heavy drop shadows and dark “AI dashboard” panels

## 7. Explicit non-goals / Discourse hard limits

Cannot fully match without forking Discourse:

1. Custom multi-item top mega-nav identical to zeekr.eu IA  
2. Exact ZeekrText/ZeekrHeadline font files  
3. Nuxt page transitions / full-bleed marketing layout engine  
4. Replacing sidebar information architecture with a marketing site IA  
5. Removing all Discourse topic-list / composer chrome  

Acceptable residual: Discourse sidebar + topic list structure, search iconography, composer — restyled only.

## 8. Implementation contract (this Project)

- **ONE theme:** Foundation (neutral shell)  
- **ONE component:** Foro Zeekr  
- Competing themes (Horizon/Air/Graceful/Mint) **not default / not selectable**  
- Hero: short full-width banner placeholder; **no car strip**  
- Tab label: `Caliente` → `Top`  
- Drop custom hero: `themes/forozeekr/assets/hero.jpg` then `./scripts/install-forozeekr-theme.sh`

## 9. Self-review vs live site (iteration log)

### Pass A — applied

| Requirement | Status |
|-------------|--------|
| Palette `#24292B` / white / `#F5F5F5` wash | Done (`Foro Zeekr Light`) |
| Inter + SF Pro fallbacks (stand-in for ZeekrText) | Done |
| Wordmark graphite tracked caps `FORO ZEEKR` | Done (SVG) |
| Full-width short hero placeholder; no car strip | Done |
| Welcome banner off | Done |
| `Caliente` → `Top` | Done (TranslationOverride + theme locale) |
| Single path Foundation + Foro Zeekr; others not selectable | Done |
| Buttons graphite 2px radius | Done |

### Pass B — topic page contrast (2026-11-17)

| Requirement | Status |
|-------------|--------|
| Map Discourse vars: `--primary=#000`, graphite `#24292B` for buttons, `--primary-medium=#666` for meta | Done |
| Never use wash `#EBEBEB` / `--primary-low` as text | Done |
| Signup CTA Spanish `value_prop` (core `client.es.yml` lacked key → English fallback) | Done — yaml patch + TranslationOverride + theme JS force + locale cache clear |
| Registrarse: white label on graphite (`#fff` on `#24292B`); no blanket `.signup-cta *` color | Done |
| Topic title `#000`; visits/tags/chips `#666` min | Done |

### Residual gaps (hard Discourse limits)

1. Cannot reproduce zeekr.eu multi-link marketing nav (Cars/Shop/Discover) — Discourse uses sidebar + top_menu filters.  
2. Cannot ship proprietary `ZeekrText` / `ZeekrHeadline` font files.  
3. Topic list / composer / user menu remain Discourse chrome (restyled only).  
4. Exact Nuxt header height/animation/hover megamenus not portable.  

### Assets still needed from user for final polish

- Official wordmark if legal/design requires exact Zeekr lettering → `themes/forozeekr/assets/logo.svg`  
- Custom hero photo → `themes/forozeekr/assets/hero.jpg` (~1920×360), then `./scripts/install-forozeekr-theme.sh`
