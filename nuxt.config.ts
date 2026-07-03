export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  devtools: { enabled: true },
  modules: ['@nuxt/eslint', 'vuetify-nuxt-module', '@nuxtjs/supabase'],
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
