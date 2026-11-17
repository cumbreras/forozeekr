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

# zeekr.eu graphite/white palette
scheme = ColorScheme.find_by(name: "Foro Zeekr Light") || ColorScheme.new(name: "Foro Zeekr Light")
scheme.user_selectable = true
scheme.colors = [
  { name: "primary", hex: "24292B" },
  { name: "secondary", hex: "FFFFFF" },
  { name: "tertiary", hex: "24292B" },
  { name: "quaternary", hex: "353738" },
  { name: "header_background", hex: "FFFFFF" },
  { name: "header_primary", hex: "232323" },
  { name: "highlight", hex: "24292B" },
  { name: "danger", hex: "D2211E" },
  { name: "success", hex: "65C466" },
  { name: "love", hex: "D2211E" },
]
scheme.save!

foundation.update!(
  color_scheme_id: scheme.id,
  dark_color_scheme_id: ColorScheme.find_by(name: "Dark")&.id,
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

%w[js.filters.hot.title js.filters.top.title].each do |key|
  o = TranslationOverride.find_or_initialize_by(locale: "es", translation_key: key)
  o.value = "Top"
  o.save!
end
I18n.reload! rescue nil
Stylesheet::Manager.clear_theme_cache! rescue nil

puts "DEFAULT=#{Theme.find_default.name}"
puts "CHILDREN=#{Theme.find_default.child_themes.map(&:name)}"
puts "SELECTABLE=#{Theme.where(user_selectable: true, component: false).pluck(:name)}"
puts "LOGO=#{SiteSetting.logo}"
puts "HERO=#{assets["hero"]}"
puts "HOT=#{I18n.t("js.filters.hot.title", locale: :es)}"
'
echo "Hard-refresh http://127.0.0.1:3000/"
echo "Custom hero: themes/forozeekr/assets/hero.jpg then re-run"
