// Load synchronously before styles: the saved appearance is applied before paint.
// This controller lives outside Stimulus so Turbo visits do not reset the theme.
(() => {
  const key = "crewbase.theme"
  const system = window.matchMedia("(prefers-color-scheme: dark)")
  const normalize = value => ["light", "dark", "system"].includes(value) ? value : "system"
  let preference = "system"
  try { preference = normalize(localStorage.getItem(key)) } catch (_) { /* Storage may be disabled. */ }

  function apply() {
    const theme = preference === "system" ? (system.matches ? "dark" : "light") : preference
    document.documentElement.dataset.bsTheme = theme
    document.documentElement.style.colorScheme = theme
    document.querySelectorAll("[data-theme-choice]").forEach(select => { select.value = preference })
    document.dispatchEvent(new CustomEvent("theme:changed", { detail: { theme } }))
  }

  document.addEventListener("change", event => {
    if (!event.target.matches("[data-theme-choice]")) return
    preference = normalize(event.target.value)
    try { localStorage.setItem(key, preference) } catch (_) { /* The current page still works. */ }
    apply()
  })
  window.addEventListener("storage", event => {
    if (event.key !== key && event.key !== null) return
    preference = normalize(event.newValue)
    apply()
  })
  system.addEventListener("change", () => { if (preference === "system") apply() })
  document.addEventListener("turbo:load", apply)
  document.addEventListener("turbo:before-render", apply)
  document.addEventListener("DOMContentLoaded", apply)
  window.addEventListener("pageshow", apply)
  apply()
})()
