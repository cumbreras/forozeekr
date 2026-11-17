# frozen_string_literal: true
# Idempotent Spanish branding + IA seed for Foro Zeekr (local/dev).
# Aligns with docs/forum-competitive-analysis.md:
# intent categories + model tags (no board explosion), Categories+Latest home.
# Run via: ./scripts/seed-forozeekr.sh

SiteSetting.title = "Foro Zeekr"
SiteSetting.site_description = "Comunidad de propietarios Zeekr en español"
SiteSetting.short_site_description = "Comunidad de propietarios Zeekr en español"
SiteSetting.company_name = "Foro Zeekr"
SiteSetting.contact_email = "admin@forozeekr.local"
SiteSetting.notification_email = "noreply@forozeekr.local"
SiteSetting.default_locale = "es"
SiteSetting.allow_user_locale = false # force Spanish UI in local/dev
SiteSetting.set_locale_from_accept_language_header = false
SiteSetting.disable_discourse_narrative_bot_welcome_post = true
SiteSetting.top_menu = "categories|latest|new|hot"
SiteSetting.desktop_category_page_style = "categories_and_latest_topics"
SiteSetting.mobile_category_page_style = "categories_with_featured_topics"
SiteSetting.fixed_category_positions = true
SiteSetting.header_dropdown_category_count = 12
SiteSetting.base_font = "inter"
SiteSetting.heading_font = "inter"

CATEGORY_DEFS = [
  {
    name: "Bienvenida y reglas",
    slug: "bienvenida",
    desc: "Preséntate, lee las normas y aprende cómo publicar. Club de propietarios — no afiliado a Zeekr.",
    color: "1D9E75",
    text_color: "FFFFFF",
  },
  {
    name: "Modelos Zeekr",
    slug: "modelos-zeekr",
    desc: "Charla por modelo. Usa la etiqueta de modelo (001, 7x, x, 7gt, 009).",
    color: "0088CC",
    text_color: "FFFFFF",
  },
  {
    name: "Compra, pedidos y entrega",
    slug: "compra-entrega",
    desc: "Configuración, plazos, financiación y sala de espera de pedidos/entrega en España.",
    color: "E45735",
    text_color: "FFFFFF",
  },
  {
    name: "Carga y autonomía",
    slug: "carga-autonomia",
    desc: "Wallbox, redes públicas, viajes y consumo real.",
    color: "12A89D",
    text_color: "FFFFFF",
  },
  {
    name: "Software, app y OTA",
    slug: "software-ota",
    desc: "Actualizaciones OTA, app Zeekr, CarPlay/Android Auto y bugs.",
    color: "652D90",
    text_color: "FFFFFF",
  },
  {
    name: "Taller, garantía y seguros",
    slug: "mantenimiento",
    desc: "Servicio oficial, averías, neumáticos, garantía, IVTM y pólizas.",
    color: "92278F",
    text_color: "FFFFFF",
  },
  {
    name: "Accesorios y mods",
    slug: "accesorios",
    desc: "Accesorios oficiales y aftermarket. Hilos recomendados bienvenidos.",
    color: "F7941D",
    text_color: "FFFFFF",
  },
  {
    name: "Encuentros España",
    slug: "encuentros-espana",
    desc: "Quedadas y rutas. Usa etiquetas de CCAA cuando puedas.",
    color: "3AB54A",
    text_color: "FFFFFF",
  },
  {
    name: "Clasificados",
    slug: "clasificados",
    desc: "Particular a particular (TL1+). Sin datos personales a la vista; marca «vendido».",
    color: "5C6BC0",
    text_color: "FFFFFF",
  },
  {
    name: "Off-topic",
    slug: "off-topic",
    desc: "Charla general fuera de Zeekr. Mantén el respeto.",
    color: "808281",
    text_color: "FFFFFF",
  },
].freeze

CATEGORY_DEFS.each_with_index do |d, i|
  cat = Category.find_by_slug(d[:slug]) || Category.new
  cat.name = d[:name]
  cat.slug = d[:slug]
  cat.color = d[:color]
  cat.text_color = d[:text_color]
  cat.user ||= Discourse.system_user
  cat.position = i
  cat.save!
  puts "Category OK: #{cat.name}"
end

# Cleanup English defaults if still present
admin = User.find_by_email("admin@forozeekr.local") || User.admins.first
guardian = Guardian.new(admin) if admin
%w[site-feedback general].each do |slug|
  cat = Category.find_by_slug(slug)
  next unless cat && guardian
  begin
    CategoryDestroyer.destroy(guardian, cat)
    puts "Destroyed leftover #{slug}"
  rescue => e
    puts "Skip destroy #{slug}: #{e.message}"
  end
end

uncat = Category.find_by(id: SiteSetting.uncategorized_category_id)
if uncat
  uncat.update!(name: "Sin categoría")
end

staff = Category.find_by_slug("staff")
if staff
  staff.update!(name: "Equipo", read_restricted: true)
end

# Model + intent tags
model_names = %w[001 7x x 7gt 009]
intent_names = %w[entrega averia ota wallbox viaje]
all_tag_names = model_names + intent_names

all_tag_names.each do |name|
  Tag.find_by_name(name) || Tag.create!(name: name)
end

modelo_group = TagGroup.find_by(name: "Modelo") || TagGroup.new(name: "Modelo")
modelo_group.save!
modelo_group.tags = model_names.map { |n| Tag.find_by_name(n) }.compact
modelo_group.save!

# Prefer model tags on key categories (soft guidance; full "required" via category settings)
tag_slugs = %w[modelos-zeekr compra-entrega carga-autonomia software-ota mantenimiento accesorios]
tag_slugs.each do |slug|
  cat = Category.find_by_slug(slug)
  next unless cat
  cat.allowed_tag_groups = ["Modelo"] if cat.respond_to?(:allowed_tag_groups=)
  begin
    cat.update!(allow_global_tags: true) if cat.respond_to?(:allow_global_tags)
  rescue StandardError
    # ignore older schemas
  end
end

# Nav: all public intent categories
ids =
  Category
    .where(
      slug:
        %w[
          bienvenida
          modelos-zeekr
          compra-entrega
          carga-autonomia
          software-ota
          mantenimiento
          accesorios
          encuentros-espana
          clasificados
          off-topic
        ],
    )
    .order(:position)
    .pluck(:id)
SiteSetting.default_navigation_menu_categories = ids.join("|")
bienvenida = Category.find_by_slug("bienvenida")
SiteSetting.default_composer_category = bienvenida.id if bienvenida

# Spanish about texts
about_es = {
  "bienvenida" =>
    "Preséntate y lee las normas. Foro Zeekr es un club de propietarios **independiente** (sin afiliación a Zeekr/Geely/concesionarios).",
  "modelos-zeekr" =>
    "Habla de tu coche. Etiqueta el modelo: `001`, `7x`, `x`, `7gt` o `009`.",
  "compra-entrega" =>
    "Pedidos, plazos, financiación y entregas. Usa la etiqueta de modelo + `entrega`.",
  "carga-autonomia" => "Wallbox, Ionity/Zunder y autonomía real. Etiqueta `wallbox` o `viaje` si aplica.",
  "software-ota" => "OTA, app y conectividad. Etiqueta `ota` + modelo.",
  "mantenimiento" => "Taller, garantía, averías y seguros. Etiqueta `averia` si es un fallo.",
  "accesorios" => "OEM y aftermarket. Incluye el tag de modelo.",
  "encuentros-espana" => "Quedadas por CCAA. Propón fecha, sitio y modelo.",
  "clasificados" =>
    "Solo particulares. Sin teléfono/VIN a la vista; cuando se venda, edita el título con «vendido».",
  "off-topic" => "Todo lo demás, con respeto.",
}
about_es.each do |slug, desc|
  cat = Category.find_by_slug(slug)
  next unless cat&.topic&.first_post
  cat.topic.first_post.revise(
    Discourse.system_user,
    { title: "Sobre la categoría #{cat.name}", raw: desc },
    skip_validations: true,
  )
end

# Welcome + reglas
if bienvenida
  welcome =
    Topic.where(category_id: bienvenida.id).where("title ILIKE ?", "%Bienvenid%").first
  raw_welcome = <<~MD
    ¡Hola! Esto es **Foro Zeekr**, comunidad de propietarios Zeekr en español.

    - Preséntate (modelo + ciudad/CCAA)
    - Usa la **etiqueta de modelo** en temas técnicos
    - Los pedidos/entregas van en **Compra, pedidos y entrega**
    - Somos un club **independiente** — sin afiliación a la marca

    Normas rápidas: respeto, cero spam, sin datos personales a la vista, divulga si trabajas en concesionario/marca.
  MD
  if welcome&.first_post
    welcome.first_post.revise(
      Discourse.system_user,
      { title: "Bienvenido/a a Foro Zeekr", raw: raw_welcome },
      skip_validations: true,
    )
  else
    PostCreator.create!(
      Discourse.system_user,
      title: "Bienvenido/a a Foro Zeekr",
      raw: raw_welcome,
      category: bienvenida.id,
      skip_validations: true,
    )
  end

  unless Topic.where(category_id: bienvenida.id).where("title ILIKE ?", "%Normas%").exists?
    PostCreator.create!(
      Discourse.system_user,
      title: "Normas de la comunidad",
      raw:
        "1. Sé respetuoso.\n2. No spam ni publicidad no solicitada.\n3. Usa categoría y etiqueta de modelo.\n4. Sin datos personales públicos.\n5. Empleados de marca/dealer: identifícate.\n6. El equipo puede moderar incumplimientos.",
      category: bienvenida.id,
      skip_validations: true,
    )
  end
end

# Wartezimmer / sala de pedidos por modelo
compra = Category.find_by_slug("compra-entrega")
if compra
  model_names.each do |model|
    title = "Pedidos y entregas España — Zeekr #{model.upcase}"
    next if Topic.where(category_id: compra.id).where(title: title).exists?
    post =
      PostCreator.create!(
        Discourse.system_user,
        title: title,
        raw:
          "Hilo evergreen para pedidos y entregas del **Zeekr #{model.upcase}** en España.\n\nCuenta: fecha de pedido, configuración, concesionario (sin doxxear), estado y fecha de entrega cuando llegue.\n\nEtiquetas: `#{model}` `entrega`",
        category: compra.id,
        tags: [model, "entrega"],
        skip_validations: true,
      )
    puts "Wartezimmer: #{title} (#{post.topic_id})"
  end
end

# Color scheme (analysis: teal on graphite)
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
  { name: "success", hex: "3AB54A" },
  { name: "love", hex: "E45735" },
]
scheme.save!
theme = Theme.find_default
theme.update!(color_scheme_id: scheme.id) if theme

puts "Locale=#{SiteSetting.default_locale} title=#{SiteSetting.title} nav=#{SiteSetting.default_navigation_menu_categories}"
puts "Tags modelo=#{model_names.join(",")}"
