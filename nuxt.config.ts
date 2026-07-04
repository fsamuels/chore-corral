export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  devtools: { enabled: true },
  modules: ['@nuxt/eslint', 'vuetify-nuxt-module', '@nuxtjs/supabase'],
  vuetify: {
    vuetifyOptions: {
      theme: {
        defaultTheme: 'classic-light',
        // Equipment-brand themes; selected per user via the account menu
        // (see app/composables/useThemePreference.ts).
        themes: {
          'classic-light': {
            dark: false,
            colors: { primary: '#1867C0', secondary: '#5CBBF6' },
          },
          'classic-dark': {
            dark: true,
            colors: { primary: '#2196F3', secondary: '#5CBBF6' },
          },
          'deere-light': {
            dark: false,
            colors: { primary: '#367C2B', secondary: '#FFDE00' },
          },
          'deere-dark': {
            dark: true,
            colors: { primary: '#4C9A41', secondary: '#FFDE00' },
          },
          'kubota-light': {
            dark: false,
            colors: { primary: '#DF5C2A', secondary: '#3A3A3A' },
          },
          'kubota-dark': {
            dark: true,
            colors: { primary: '#F36F21', secondary: '#B0B0B0' },
          },
          'massey-light': {
            dark: false,
            colors: { primary: '#A6192E', secondary: '#58595B' },
          },
          'massey-dark': {
            dark: true,
            colors: { primary: '#C93C50', secondary: '#9EA0A3' },
          },
        },
      },
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
