#!/usr/bin/env bash
# Install/update restrained Foro Zeekr theme component on light Horizon.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/themes/forozeekr"
DEST="${ROOT}/discourse/tmp/forozeekr-theme"

if ! docker ps --format '{{.Names}}' | grep -qx discourse_dev; then
  echo "discourse_dev not running"
  exit 1
fi

rm -rf "${DEST}"
mkdir -p "${DEST}"
# copy without huge git noise; include cars + logo
/bin/cp -R "${SRC}/." "${DEST}/"

docker exec -u discourse:discourse -w /src \
  -e RAILS_ENV=development \
  -e RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
  -e LD_PRELOAD=/usr/lib/libjemalloc.so \
  discourse_dev bundle exec rails runner '
dir = "/src/tmp/forozeekr-theme"
existing = Theme.find_by(name: "Foro Zeekr", component: true)
theme =
  if existing
    RemoteTheme.import_theme_from_directory(dir, theme_id: existing.id)
  else
    RemoteTheme.import_theme_from_directory(dir)
  end
theme.update!(component: true, user_selectable: false)

horizon = Theme.find_by(name: "Horizon")
# ensure only this child
ChildTheme.where(parent_theme_id: horizon.id).where.not(child_theme_id: theme.id).delete_all
horizon.add_relative_theme!(:child, theme) unless horizon.child_themes.include?(theme)

# Light Zeekr-tinted palette (based on Horizon light, teal tertiary)
scheme = ColorScheme.find_by(name: "Foro Zeekr Light") || ColorScheme.new(name: "Foro Zeekr Light")
scheme.user_selectable = true
scheme.base_scheme_id = "Light" rescue nil
scheme.colors = [
  { name: "primary", hex: "0B1218" },
  { name: "secondary", hex: "FFFFFF" },
  { name: "tertiary", hex: "00B3A6" },
  { name: "quaternary", hex: "00B3A6" },
  { name: "header_background", hex: "FFFFFF" },
  { name: "header_primary", hex: "0B1218" },
  { name: "highlight", hex: "00B3A6" },
  { name: "danger", hex: "D2211E" },
  { name: "success", hex: "3AB54A" },
  { name: "love", hex: "E45735" },
]
scheme.save!

horizon_dark = ColorScheme.find_by(name: "Horizon Dark")
horizon.update!(color_scheme_id: scheme.id, dark_color_scheme_id: horizon_dark&.id)
horizon.set_default!

SiteSetting.base_font = "inter"
SiteSetting.heading_font = "inter"
SiteSetting.default_locale = "es"
SiteSetting.allow_user_locale = false

# Prefer our short hero over stock Horizon welcome banner
rec = ThemeSiteSetting.find_or_initialize_by(theme_id: horizon.id, name: "enable_welcome_banner")
rec.value = "f"
rec.save!
SiteSetting.change_themeable_site_setting(horizon.id, :enable_welcome_banner, false)

# Resolve theme asset URLs into after_header (Discourse HTML does not expand {{asset}})
assets = {}
theme.theme_fields.where.not(upload_id: nil).each { |f| assets[f.name] = f.upload.url }
if assets["car-001"]
  html = theme.theme_fields.find_by(name: "after_header", target_id: 0)&.value.to_s
  assets.each { |name, url| html = html.gsub("{{#{name}}}", url) }
  theme.set_field(target: :common, name: "after_header", value: html)
  theme.save!
end

# Site logo from theme asset
if (logo_upload = theme.theme_fields.find_by(name: "logo")&.upload)
  SiteSetting.logo = logo_upload
  SiteSetting.logo_small = logo_upload
  puts "Logo=#{logo_upload.url}"
end

Stylesheet::Manager.clear_theme_cache! rescue nil
puts "OK theme=#{theme.id} children=#{horizon.reload.child_themes.map(&:name)} scheme=#{horizon.color_scheme.name}"
puts "welcome_banner=#{ThemeSiteSetting.find_by(theme_id: horizon.id, name: "enable_welcome_banner")&.value}"
'
echo "Hard-refresh http://127.0.0.1:3000/"
