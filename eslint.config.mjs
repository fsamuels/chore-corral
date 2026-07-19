// @ts-check
import prettier from 'eslint-config-prettier/flat'
import withNuxt from './.nuxt/eslint.config.mjs'

export default withNuxt(prettier).prepend(
  // Supabase Edge Functions run on Deno, not Node/Nuxt: they use URL/npm import
  // specifiers, `Deno.*` globals, and a JSR/Deno toolchain that this repo's
  // Nuxt-oriented ESLint config doesn't understand. They're type-checked and
  // linted by the Supabase/Deno toolchain instead, so keep ESLint out of them.
  { ignores: ['supabase/functions/**'] },
)
