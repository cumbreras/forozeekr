import { apiInitializer } from "discourse/lib/api";

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
  api.onPageChange(syncHero);
  requestAnimationFrame(syncHero);
  setTimeout(syncHero, 100);
});
