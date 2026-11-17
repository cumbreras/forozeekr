# frozen_string_literal: true
# Idempotent Spanish branding + category seed for Foro Zeekr (local/dev).
# Run via: ./scripts/seed-forozeekr.sh

SiteSetting.title = "Foro Zeekr"
SiteSetting.site_description = "Comunidad española de propietarios y entusiastas Zeekr"
SiteSetting.short_site_description = "Comunidad Zeekr en español"
SiteSetting.company_name = "Foro Zeekr"
SiteSetting.contact_email = "admin@forozeekr.local"
SiteSetting.notification_email = "noreply@forozeekr.local"
SiteSetting.default_locale = "es"
SiteSetting.allow_user_locale = true
SiteSetting.set_locale_from_accept_language_header = true

CATEGORY_DEFS = [
  {
    name: "Bienvenida",
    slug: "bienvenida",
    desc: "Preséntate y conoce a la comunidad",
    color: "1D9E75",
    text_color: "FFFFFF",
  },
  {
    name: "Modelos Zeekr",
    slug: "modelos-zeekr",
    desc: "Zeekr 001, 7X, X, 009 y futuros modelos",
    color: "0088CC",
    text_color: "FFFFFF",
  },
  {
    name: "Compra y entrega",
    slug: "compra-entrega",
    desc: "Pedidos, concesionarios, financiación y entregas en España",
    color: "E45735",
    text_color: "FFFFFF",
  },
  {
    name: "Carga y autonomía",
    slug: "carga-autonomia",
    desc: "Cargadores, wallbox, viajes y autonomía real",
    color: "12A89D",
    text_color: "FFFFFF",
  },
  {
    name: "Software y OTA",
    slug: "software-ota",
    desc: "Actualizaciones, apps, conectividad y bugs",
    color: "652D90",
    text_color: "FFFFFF",
  },
  {
    name: "Mantenimiento y taller",
    slug: "mantenimiento",
    desc: "Servicio oficial, neumáticos, seguros y reparaciones",
    color: "92278F",
    text_color: "FFFFFF",
  },
  {
    name: "Accesorios y mods",
    slug: "accesorios",
    desc: "Accesorios oficiales y personalización",
    color: "F7941D",
    text_color: "FFFFFF",
  },
  {
    name: "Encuentros España",
    slug: "encuentros-espana",
    desc: "Quedadas, rutas y eventos por comunidades",
    color: "3AB54A",
    text_color: "FFFFFF",
  },
  {
    name: "Off-topic",
    slug: "off-topic",
    desc: "Charla general fuera de Zeekr",
    color: "808281",
    text_color: "FFFFFF",
  },
].freeze

CATEGORY_DEFS.each do |d|
  cat = Category.find_by_slug(d[:slug]) || Category.new
  cat.name = d[:name]
  cat.slug = d[:slug]
  cat.color = d[:color]
  cat.text_color = d[:text_color]
  cat.user ||= Discourse.system_user
  cat.save!
  puts "Category OK: #{cat.name}"
end

welcome = Category.find_by_slug("bienvenida")
unless Topic.where(category_id: welcome.id).where("title ILIKE ?", "%Bienvenid%").exists?
  PostCreator.create!(
    Discourse.system_user,
    title: "Bienvenido/a a Foro Zeekr",
    raw:
      "¡Hola! Este es el foro de la comunidad española de **Zeekr**.\n\n" \
        "Aquí puedes presentarte, preguntar sobre compra/carga/software y organizar encuentros en España.\n\n" \
        "Dominio de producción previsto: https://forozeekr.com",
    category: welcome.id,
    skip_validations: true,
  )
  puts "Welcome topic created"
else
  puts "Welcome topic already exists"
end

scheme = ColorScheme.find_by(name: "Foro Zeekr") || ColorScheme.new(name: "Foro Zeekr")
scheme.user_selectable = true
colors = {
  "primary" => "E8EEF2",
  "secondary" => "0B1218",
  "tertiary" => "00B3A6",
  "quaternary" => "00B3A6",
  "header_background" => "0B1218",
  "header_primary" => "E8EEF2",
  "highlight" => "00B3A6",
  "danger" => "E45735",
  "success" => "3AB54A",
  "love" => "E45735",
}
scheme.colors = colors.map { |n, h| { name: n, hex: h } }
scheme.save!

theme = Theme.find_default
theme.color_scheme_id = scheme.id
theme.save!

puts "Locale=#{SiteSetting.default_locale} title=#{SiteSetting.title} scheme=#{scheme.id}"
