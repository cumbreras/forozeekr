import { apiInitializer } from "discourse/lib/api";

function isHomePath(url) {
  if (!url) {
    return false;
  }
  const path = url.split("?")[0];
  return (
    path === "/" ||
    path === "" ||
    path.startsWith("/categories") ||
    path.startsWith("/latest") ||
    path.startsWith("/new") ||
    path.startsWith("/hot") ||
    path.startsWith("/top")
  );
}

function syncChrome() {
  const chrome = document.querySelector("[data-forozeekr-chrome]");
  if (!chrome) {
    return;
  }

  // `settings` is injected by Discourse theme build from settings.yml
  const heroEnabled = typeof settings === "undefined" || settings.show_hero !== false;
  const adsEnabled = typeof settings !== "undefined" && settings.show_ad_slots === true;

  const home = isHomePath(window.location.pathname);
  const visible = home && heroEnabled;

  // CSS also keys off body.navigation-* ; is-home is an explicit override.
  chrome.classList.toggle("is-home", visible);
  chrome.classList.toggle("ads-on", adsEnabled);
  if (!heroEnabled) {
    chrome.style.display = "none";
  } else if (visible) {
    chrome.style.display = "";
  }
}

export default apiInitializer((api) => {
  api.onPageChange(syncChrome);
  requestAnimationFrame(syncChrome);
  setTimeout(syncChrome, 50);
  setTimeout(syncChrome, 300);
});
