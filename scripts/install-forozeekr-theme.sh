#!/usr/bin/env bash
# Install/update the local Foro Zeekr theme component into discourse_dev and attach to Horizon.
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
cp -R "${SRC}/." "${DEST}/"

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

horizon = Theme.find_by(name: "Horizon") || Theme.find_default
horizon.add_relative_theme!(:child, theme) unless horizon.child_themes.include?(theme)
horizon.save!

# Ensure Horizon remains default with Zeekr palette + Inter
scheme = ColorScheme.find_by(name: "Foro Zeekr") || ColorScheme.new(name: "Foro Zeekr")
scheme.user_selectable = true
scheme.colors = [
  { name: "primary", hex: "0B1218" },
  { name: "secondary", hex: "FAFBFB" },
  { name: "tertiary", hex: "00B3A6" },
  { name: "quaternary", hex: "00B3A6" },
  { name: "header_background", hex: "FAFBFB" },
  { name: "header_primary", hex: "0B1218" },
  { name: "highlight", hex: "00B3A6" },
  { name: "danger", hex: "D2211E" },
  { name: "success", hex: "65C466" },
  { name: "love", hex: "D2211E" },
]
scheme.save!
horizon.update!(color_scheme_id: scheme.id)
horizon.set_default!

SiteSetting.base_font = "inter"
SiteSetting.heading_font = "inter"

puts "Theme component id=#{theme.id} attached to #{horizon.name}"
puts "Children: #{horizon.child_themes.map(&:name).join(", ")}"
'
echo "Done. Hard-refresh http://127.0.0.1:3000/"
