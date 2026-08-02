import tailwindcss from '@tailwindcss/vite'

// Fully client-side app (all state lives in localStorage) → SPA mode,
// statically generated for GitHub Pages.
export default defineNuxtConfig({
  ssr: false,
  compatibilityDate: '2026-08-01',
  devtools: { enabled: false },

  app: {
    baseURL: '/leben-in-deutschland/',
    head: {
      title: 'Leben in Deutschland – Testtrainer',
      htmlAttrs: { lang: 'de' },
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        { name: 'theme-color', content: '#1a1a1f' },
        {
          name: 'description',
          content:
            'Lern-App für den Test „Leben in Deutschland“ / Einbürgerungstest – alle 300 Fragen + Bundesland-Fragen, offline, kostenlos.',
        },
        { name: 'mobile-web-app-capable', content: 'yes' },
        { name: 'apple-mobile-web-app-status-bar-style', content: 'black-translucent' },
        { name: 'apple-mobile-web-app-title', content: 'LiD Trainer' },
      ],
      link: [
        { rel: 'icon', href: '/leben-in-deutschland/icons/icon-192.png' },
        { rel: 'apple-touch-icon', href: '/leben-in-deutschland/icons/icon-192.png' },
      ],
    },
  },

  css: ['~/assets/css/main.css'],
  vite: { plugins: [tailwindcss()] },

  modules: ['@vite-pwa/nuxt'],
  pwa: {
    registerType: 'autoUpdate',
    manifest: {
      name: 'Leben in Deutschland – Testtrainer',
      short_name: 'LiD Trainer',
      description:
        'Alle 300 Fragen + Bundesland-Fragen für den Test „Leben in Deutschland“ / Einbürgerungstest. Offline, kostenlos, ohne Konto.',
      lang: 'de',
      start_url: '/leben-in-deutschland/',
      scope: '/leben-in-deutschland/',
      display: 'standalone',
      orientation: 'portrait',
      background_color: '#fafaf7',
      theme_color: '#1a1a1f',
      icons: [
        { src: 'icons/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any maskable' },
        { src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any maskable' },
      ],
    },
    workbox: {
      // precache the app shell AND all question data/images → full offline
      globPatterns: ['**/*.{js,css,html,png,jpg,svg,json,webmanifest,ico}'],
      // 200.html/404.html become extensionless routes static hosts can't
      // serve — precaching them makes the SW install fail
      globIgnores: ['200.html', '404.html'],
      maximumFileSizeToCacheInBytes: 4 * 1024 * 1024,
      navigateFallback: '/leben-in-deutschland/',
    },
  },
})
