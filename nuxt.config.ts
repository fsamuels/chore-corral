export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  devtools: { enabled: true },
  modules: ['@nuxt/eslint', 'vuetify-nuxt-module', '@nuxtjs/supabase'],
  css: ['~/assets/css/main.css'],
  app: {
    head: {
      // Cover the notch/safe areas so the standalone (home-screen) app can
      // paint edge-to-edge; the header/nav already sit inside normal padding.
      viewport: 'width=device-width, initial-scale=1, viewport-fit=cover',
      link: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        {
          rel: 'preconnect',
          href: 'https://fonts.gstatic.com',
          crossorigin: '',
        },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Zilla+Slab:wght@500;600;700&family=Inter:wght@400;500;600;700&display=swap',
        },
        // PWA / install-to-home-screen assets (files live in /public).
        { rel: 'manifest', href: '/manifest.webmanifest' },
        { rel: 'icon', type: 'image/svg+xml', href: '/icon.svg' },
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        {
          rel: 'icon',
          type: 'image/png',
          sizes: '32x32',
          href: '/favicon-32x32.png',
        },
        {
          rel: 'icon',
          type: 'image/png',
          sizes: '16x16',
          href: '/favicon-16x16.png',
        },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
      ],
      meta: [
        // Cream status bar to match the app's warm background (Android).
        { name: 'theme-color', content: '#f7f3ea' },
        // iOS standalone: run full-screen, dark status-bar text on cream,
        // and label the home-screen icon.
        { name: 'apple-mobile-web-app-capable', content: 'yes' },
        { name: 'mobile-web-app-capable', content: 'yes' },
        {
          name: 'apple-mobile-web-app-status-bar-style',
          content: 'default',
        },
        { name: 'apple-mobile-web-app-title', content: 'Chore Corral' },
        { name: 'application-name', content: 'Chore Corral' },
      ],
    },
  },
  vuetify: {
    vuetifyOptions: {
      // App-wide component defaults. The ranch look is soft and pill-shaped
      // (see the `cc-*` classes in main.css); these push Vuetify's own
      // controls the same way so buttons/inputs/cards aren't sharp-cornered,
      // and bumps the default touch density up for comfortable tapping on
      // mobile.
      defaults: {
        global: { rounded: 'lg' },
        VBtn: { rounded: 'xl' },
        VTextField: { rounded: 'lg' },
        VSelect: { rounded: 'lg' },
        VCombobox: { rounded: 'lg' },
        VAutocomplete: { rounded: 'lg' },
        VTextarea: { rounded: 'lg' },
        VCard: { rounded: 'lg' },
        VChip: { rounded: 'lg' },
        VListItem: { rounded: 'lg' },
      },
      theme: {
        defaultTheme: 'ranch',
        // Single warm "ranch" theme; palette tokens also live as CSS custom
        // properties in app/assets/css/main.css.
        themes: {
          ranch: {
            dark: false,
            colors: {
              primary: '#b5541e', // burnt orange accent
              secondary: '#8ba06b', // sage green (whenever ring)
              background: '#f7f3ea', // warm cream
              surface: '#fdfcf9', // near-white warm card
              error: '#c0391f', // urgent ring red
              warning: '#d98a1a', // soon amber
              'on-background': '#2b2118',
              'on-surface': '#2b2118',
            },
          },
        },
      },
    },
  },
  vite: {
    optimizeDeps: {
      // cookie@1 is CJS-only but @supabase/ssr does a named ESM import from
      // it; without pre-bundling, the client entry dies with "does not
      // provide an export named 'parse'" and the app never hydrates in dev.
      include: ['cookie'],
    },
  },
  runtimeConfig: {
    public: {
      // Mapbox public access token, set via NUXT_PUBLIC_MAPBOX_TOKEN. Empty
      // means no Mapbox layers — the map falls back to OSM-only (see
      // app/utils/map-tiles.ts).
      mapboxToken: '',
      // Web Push VAPID public key, set via NUXT_PUBLIC_VAPID_PUBLIC_KEY —
      // public like the Mapbox token above (it's handed to PushManager.subscribe
      // client-side; the matching private key is a Supabase Edge Function
      // secret, never here). Empty means chore reminders stay unavailable
      // (see usePushNotifications.ts).
      vapidPublicKey: '',
    },
  },
  supabase: {
    // url/key come from NUXT_PUBLIC_SUPABASE_URL / NUXT_PUBLIC_SUPABASE_KEY,
    // the module's default env vars (already set locally and in Vercel).
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      // Static Vuetify sampler with no data access; everything else requires auth.
      exclude: ['/components-demo'],
    },
  },
})
