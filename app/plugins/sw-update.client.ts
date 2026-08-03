// Browsers only check for a new service worker on navigation, so a standalone
// PWA resumed from memory (never navigating) can serve stale precached data
// indefinitely. Trigger the update check whenever the app returns to the
// foreground; `registerType: 'autoUpdate'` handles the rest (install →
// activate → page reload).
export default defineNuxtPlugin(() => {
  if (!('serviceWorker' in navigator)) return

  const MIN_INTERVAL_MS = 60_000
  let lastCheck = 0

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState !== 'visible') return
    const now = Date.now()
    if (now - lastCheck < MIN_INTERVAL_MS) return
    lastCheck = now
    navigator.serviceWorker
      .getRegistration()
      .then((reg) => reg?.update())
      .catch(() => {})
  })
})
