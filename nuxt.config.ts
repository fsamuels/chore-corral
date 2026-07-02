export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  devtools: { enabled: true },
  modules: ['@nuxt/eslint', 'vuetify-nuxt-module'],
  runtimeConfig: {
    public: {
      // Overridden by NUXT_PUBLIC_SUPABASE_URL / NUXT_PUBLIC_SUPABASE_KEY.
      // Wired in M1; first consumed for real data in M2/M3.
      supabaseUrl: '',
      supabaseKey: '',
    },
  },
})
