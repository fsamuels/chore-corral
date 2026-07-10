export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  devtools: { enabled: true },
  modules: ['@nuxt/eslint', 'vuetify-nuxt-module', '@nuxtjs/supabase'],
  css: ['~/assets/css/main.css'],
  app: {
    head: {
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
