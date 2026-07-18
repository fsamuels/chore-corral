import type { Database } from '~/types/database.types'
import { acceptPendingInvites } from '~/services/farms'

// Routes that don't require a farm membership: the auth flow itself, the
// welcome/create-a-farm page it redirects to, and the public Vuetify sampler
// (also in supabase.redirectOptions.exclude in nuxt.config.ts).
const MEMBERSHIP_EXEMPT = ['/login', '/confirm', '/welcome', '/components-demo']

/**
 * Membership gate (SPEC.md — Authentication): once per session, sweep any
 * pending farm invites addressed to this account's email (auto-join), then
 * send an authenticated user who still belongs to no farm to /welcome, where
 * they can create their own farm. Unauthenticated users are handled by the
 * Supabase module's auth middleware. If the farms query itself fails (e.g.
 * schema not migrated yet), the user proceeds and the page surfaces
 * `farmsError` rather than misreporting the failure as "no access".
 */
export default defineNuxtRouteMiddleware(async (to) => {
  if (MEMBERSHIP_EXEMPT.includes(to.path)) return

  const user = useSupabaseUser()
  if (!user.value) return

  const { fetchFarms, refreshFarms, invitesChecked } = useFarms()

  if (!invitesChecked.value) {
    invitesChecked.value = true
    const supabase = useSupabaseClient<Database>()
    try {
      const joinedFarmIds = await acceptPendingInvites(supabase)
      if (joinedFarmIds.length > 0) await refreshFarms()
    } catch {
      // Non-fatal: worst case an invited user lands on /welcome this session
      // and the sweep runs again next session. Deliberately not surfaced —
      // most sessions have no pending invites and nothing to report.
    }
  }

  const farms = await fetchFarms()
  if (farms !== null && farms.length === 0) {
    return navigateTo('/welcome')
  }
})
