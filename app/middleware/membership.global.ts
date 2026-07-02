// Routes that don't require a farm membership: the auth flow itself, the
// no-access page it redirects to, and the public Vuetify sampler (also in
// supabase.redirectOptions.exclude in nuxt.config.ts).
const MEMBERSHIP_EXEMPT = [
  '/login',
  '/confirm',
  '/no-access',
  '/components-demo',
]

/**
 * Invite-only membership gate (SPEC.md — Authentication): an authenticated
 * user who belongs to no farm is sent to /no-access instead of an empty app.
 * Unauthenticated users are handled by the Supabase module's auth middleware.
 * If the farms query itself fails (e.g. schema not migrated yet), the user
 * proceeds and the page surfaces `farmsError` rather than misreporting the
 * failure as "no access".
 */
export default defineNuxtRouteMiddleware(async (to) => {
  if (MEMBERSHIP_EXEMPT.includes(to.path)) return

  const user = useSupabaseUser()
  if (!user.value) return

  const { fetchFarms } = useFarms()
  const farms = await fetchFarms()
  if (farms !== null && farms.length === 0) {
    return navigateTo('/no-access')
  }
})
