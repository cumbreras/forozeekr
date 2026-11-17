#!/usr/bin/env bash
# Single path: Foundation + Foro Zeekr component only. Tokens from zeekr-eu-visual-parity.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/themes/forozeekr"
DEST="${ROOT}/discourse/tmp/forozeekr-theme"

if ! docker ps --format '{{.Names}}' | grep -qx discourse_dev; then
  echo "discourse_dev not running"; exit 1
fi

rm -rf "${DEST}"
mkdir -p "${DEST}"
/bin/cp -R "${SRC}/." "${DEST}/"
[[ -f "${SRC}/assets/hero.jpg" ]] && /bin/cp -f "${SRC}/assets/hero.jpg" "${DEST}/assets/hero.jpg"
[[ -f "${SRC}/assets/hero.png" ]] && /bin/cp -f "${SRC}/assets/hero.png" "${DEST}/assets/hero.png"

# Core client.es.yml historically omits signup_cta.value_prop → English fallback.
# Patch the live Discourse checkout (gitignored) so the main locale pack is Spanish.
ES_LOCALE="${ROOT}/discourse/config/locales/client.es.yml"
if [[ -f "${ES_LOCALE}" ]] && ! grep -q 'value_prop:' "${ES_LOCALE}"; then
  python3 - "${ES_LOCALE}" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
text = p.read_text()
needle = '    signup_cta:\n'
idx = text.find(needle)
if idx < 0:
    raise SystemExit("signup_cta block missing in client.es.yml")
# Insert value_prop after intro line if present, else after signup_cta header
intro = text.find('intro:', idx)
if intro > 0:
    end = text.find("\n", intro)
    line = (
        '\n      value_prop: "¿Cansado de perder el hilo? Con una cuenta vuelves '
        "justo donde lo dejaste, recibes avisos de nuevas respuestas, guardas "
        'favoritos y das me gusta para agradecer. Entre todos hacemos mejor esta comunidad."'
    )
    p.write_text(text[:end] + line + text[end:])
    print("patched client.es.yml with signup_cta.value_prop")
else:
    raise SystemExit("signup_cta.intro missing")
PY
fi

docker exec -u discourse:discourse -w /src \
  -e RAILS_ENV=development \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  discourse_dev bundle exec rails runner '
dir = "/src/tmp/forozeekr-theme"
about = File.read("#{dir}/about.json")
if File.exist?("#{dir}/assets/hero.jpg")
  about = about.gsub(%r{"hero":\s*"[^"]+"}, "\"hero\": \"assets/hero.jpg\"")
elsif File.exist?("#{dir}/assets/hero.png")
  about = about.gsub(%r{"hero":\s*"[^"]+"}, "\"hero\": \"assets/hero.png\"")
end
File.write("#{dir}/about.json", about)

existing = Theme.find_by(name: "Foro Zeekr", component: true)
theme =
  if existing
    RemoteTheme.import_theme_from_directory(dir, theme_id: existing.id)
  else
    RemoteTheme.import_theme_from_directory(dir)
  end
theme.update!(component: true, user_selectable: false)

# ONE theme path: Foundation + this component
foundation = Theme.find_by(name: "Foundation")
horizon = Theme.find_by(name: "Horizon")

# Detach component from everyone, attach only to Foundation
ChildTheme.where(child_theme_id: theme.id).delete_all
ChildTheme.where(parent_theme_id: foundation.id).delete_all
foundation.add_relative_theme!(:child, theme)

# Disable competing themes as selectable
Theme.where(component: false).where.not(id: foundation.id).find_each do |t|
  t.update!(user_selectable: false)
end
Theme.where(component: true).where.not(id: theme.id).find_each do |t|
  t.update!(user_selectable: false)
end

# zeekr.eu light palette — primary black for readable titles
scheme = ColorScheme.find_by(name: "Foro Zeekr Light") || ColorScheme.new(name: "Foro Zeekr Light")
scheme.user_selectable = true
scheme.save!
wanted = {
  "primary" => "000000",
  "secondary" => "FFFFFF",
  "tertiary" => "24292B",
  "quaternary" => "353738",
  "header_background" => "FFFFFF",
  "header_primary" => "232323",
  "highlight" => "24292B",
  "danger" => "D2211E",
  "success" => "65C466",
  "love" => "D2211E",
}
scheme.color_scheme_colors.group_by(&:name).each do |name, rows|
  keep = rows.max_by(&:id)
  rows.reject { |r| r.id == keep.id }.each(&:destroy)
end
wanted.each do |name, hex|
  c = scheme.color_scheme_colors.find_or_initialize_by(name: name)
  c.hex = hex
  c.save!
end

# Same light scheme for dark slot — never apply Discourse Dark on topic pages
foundation.update!(
  color_scheme_id: scheme.id,
  dark_color_scheme_id: scheme.id,
  user_selectable: true,
)
foundation.set_default!

SiteSetting.base_font = "inter"
SiteSetting.heading_font = "inter"
SiteSetting.default_locale = "es"
SiteSetting.allow_user_locale = false
SiteSetting.top_menu = "categories|latest|new|hot"
SiteSetting.desktop_category_page_style = "categories_and_latest_topics"

dt = ThemeSiteSetting.where(name: "enable_welcome_banner").pick(:data_type) || 5
[foundation.id, horizon&.id].compact.uniq.each do |tid|
  rec = ThemeSiteSetting.find_by(theme_id: tid, name: "enable_welcome_banner")
  if rec
    rec.update!(value: "f")
  else
    ThemeSiteSetting.create!(theme_id: tid, name: "enable_welcome_banner", data_type: dt, value: "f")
  end
  SiteSetting.change_themeable_site_setting(tid, :enable_welcome_banner, false) rescue nil
end

assets = {}
theme.theme_fields.where.not(upload_id: nil).each { |f| assets[f.name] = f.upload.url }
field = theme.theme_fields.find_by(name: "after_header", target_id: 0)
if field
  html = field.value.to_s
  assets.each { |n, u| html = html.gsub("{{#{n}}}", u) }
  theme.set_field(target: :common, name: "after_header", value: html)
  theme.save!
end

if (logo = theme.theme_fields.find_by(name: "logo")&.upload)
  SiteSetting.logo = logo
  SiteSetting.logo_small = logo
end

{
  "js.filters.hot.title" => "Top",
  "js.filters.top.title" => "Top",
  "js.signup_cta.intro" => "¡Hola! Parece que estás disfrutando del tema, pero aún no has creado una cuenta.",
  "js.signup_cta.value_prop" => "¿Cansado de perder el hilo? Con una cuenta vuelves justo donde lo dejaste, recibes avisos de nuevas respuestas, guardas favoritos y das me gusta para agradecer. Entre todos hacemos mejor esta comunidad.",
  "js.signup_cta.sign_up" => "Registrarse",
  "js.signup_cta.hide_session" => "Tal vez más tarde",
  "js.signup_cta.hide_forever" => "No, gracias",
}.each do |key, value|
  o = TranslationOverride.find_or_initialize_by(locale: "es", translation_key: key)
  o.value = value
  o.save!
end
I18n.reload! rescue nil
ExtraLocalesController.clear_cache!(all_sites: true)
Stylesheet::Manager.clear_theme_cache! rescue nil

puts "DEFAULT=#{Theme.find_default.name}"
puts "CHILDREN=#{Theme.find_default.child_themes.map(&:name)}"
puts "SELECTABLE=#{Theme.where(user_selectable: true, component: false).pluck(:name)}"
puts "LOGO=#{SiteSetting.logo}"
puts "HERO=#{assets["hero"]}"
puts "HOT=#{I18n.t("js.filters.hot.title", locale: :es)}"
puts "CTA=#{I18n.t("js.signup_cta.value_prop", locale: :es)[0,40]}"
puts "OVERRIDES=#{ExtraLocalesController.url("overrides", locale: :es)}"
'
echo "Hard-refresh http://127.0.0.1:3000/"
echo "Custom hero: themes/forozeekr/assets/hero.jpg then re-run"
