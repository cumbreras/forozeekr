import { apiInitializer } from "discourse/lib/api";
import I18n from "discourse-i18n";

const CTA_ES = {
  intro:
    "¡Hola! Parece que estás disfrutando del tema, pero aún no has creado una cuenta.",
  value_prop:
    "¿Cansado de perder el hilo? Con una cuenta vuelves justo donde lo dejaste, recibes avisos de nuevas respuestas, guardas favoritos y das me gusta para agradecer. Entre todos hacemos mejor esta comunidad.",
  sign_up: "Registrarse",
  hide_session: "Tal vez más tarde",
  hide_forever: "No, gracias",
  hidden_for_session:
    "Vale, te lo preguntamos mañana. También puedes usar «Iniciar sesión» para crear tu cuenta.",
};

function forceSpanishSignupCta() {
  // Core es.yml historically lacked value_prop → English fallback. Force the
  // strings the signup-cta component actually reads (signup_cta.*).
  I18n.translations = I18n.translations || {};
  ["es", "en"].forEach((locale) => {
    I18n.translations[locale] = I18n.translations[locale] || {};
    I18n.translations[locale].js = I18n.translations[locale].js || {};
    I18n.translations[locale].js.signup_cta = {
      ...(I18n.translations[locale].js.signup_cta || {}),
      ...CTA_ES,
    };
  });
  if (I18n._overrides) {
    I18n._overrides.es = I18n._overrides.es || {};
    Object.entries(CTA_ES).forEach(([k, v]) => {
      I18n._overrides.es[`js.signup_cta.${k}`] = v;
    });
  }
}

function isHomePath(path) {
  if (!path) {
    return false;
  }
  const p = path.split("?")[0];
  return (
    p === "/" ||
    p === "" ||
    p.startsWith("/categories") ||
    p.startsWith("/latest") ||
    p.startsWith("/new") ||
    p.startsWith("/hot") ||
    p.startsWith("/top")
  );
}

function syncHero() {
  const el = document.querySelector("[data-fz-hero]");
  if (!el) {
    return;
  }
  const show =
    (typeof settings === "undefined" || settings.show_hero !== false) &&
    isHomePath(window.location.pathname);
  el.classList.toggle("is-home", show);
  el.style.display = show ? "" : "none";
}

export default apiInitializer((api) => {
  forceSpanishSignupCta();
  api.onPageChange(() => {
    forceSpanishSignupCta();
    syncHero();
  });
  requestAnimationFrame(syncHero);
  setTimeout(syncHero, 100);
});
