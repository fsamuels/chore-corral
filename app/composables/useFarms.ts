import type { Database } from '~/types/database.types'

const ACTIVE_FARM_COOKIE = 'cc-active-farm'
// A year, in seconds — long enough that a manual farm switch survives
// browser restarts instead of resetting every time the (previously
// session-only) cookie was dropped.
const ACTIVE_FARM_COOKIE_MAX_AGE = 60 * 60 * 24 * 365

/**
 * The current user's farms (RLS limits the `farms` table to farms the user is
 * a member of, so a farm-membership check is just "did any rows come back").
 * Fetched once per session into shared state; the active farm selection
 * persists in a cookie so it survives reloads and works during SSR.
 */
export function useFarms() {
  const supabase = useSupabaseClient<Database>()
  // null = not fetched yet; [] = fetched, user belongs to no farms
  const farms = useState<FarmSummary[] | null>('farms', () => null)
  const farmsError = useState<string | null>('farms-error', () => null)
  // Fallback for when there's no saved selection: the user's farm with the
  // most recent task activity. Only populated when needed (see fetchFarms).
  const mostRecentFarmId = useState<string | null>(
    'most-recent-farm-id',
    () => null,
  )
  const activeFarmCookie = useCookie<string | null>(ACTIVE_FARM_COOKIE, {
    default: () => null,
    maxAge: ACTIVE_FARM_COOKIE_MAX_AGE,
  })
  // Whether this session has already swept pending invites (see
  // membership.global.ts). Lives here so resetFarms() clears it on sign-out
  // and the next account's session gets its own sweep.
  const invitesChecked = useState<boolean>('invites-checked', () => false)

  async function fetchFarms(): Promise<FarmSummary[] | null> {
    if (farms.value !== null) return farms.value
    const { data, error } = await supabase
      .from('farms')
      .select('id, name, default_lat, default_lng')
      .order('name')
    if (error) {
      farmsError.value = error.message
      return null
    }
    farmsError.value = null
    farms.value = data

    // No usable saved selection (new device/browser, expired cookie, or the
    // saved farm is no longer a membership) — look up the most recently
    // active farm so the fallback isn't just alphabetical. Skipped once a
    // valid selection is on record; the cookie already tells us which farm
    // to use.
    const cookieIsValidMembership = data.some(
      (farm) => farm.id === activeFarmCookie.value,
    )
    if (!cookieIsValidMembership) {
      mostRecentFarmId.value = await fetchMostRecentFarmId()
    }
    return farms.value
  }

  async function fetchMostRecentFarmId(): Promise<string | null> {
    const { data, error } = await supabase
      .from('farm_recent_activity')
      .select('farm_id')
      .order('last_activity_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (error || !data) return null
    return data.farm_id
  }

  function resetFarms() {
    farms.value = null
    farmsError.value = null
    mostRecentFarmId.value = null
    activeFarmCookie.value = null
    invitesChecked.value = false
  }

  /**
   * Drop the cached farm list and refetch — for after the membership set
   * changes mid-session (created a farm, auto-joined via invite). Unlike
   * resetFarms(), the saved active-farm selection is kept: if it's still a
   * valid membership it should survive the refresh.
   */
  async function refreshFarms(): Promise<FarmSummary[] | null> {
    farms.value = null
    farmsError.value = null
    return fetchFarms()
  }

  const activeFarmId = computed(() =>
    resolveActiveFarmId(
      farms.value ?? [],
      activeFarmCookie.value,
      mostRecentFarmId.value,
    ),
  )
  const activeFarm = computed(
    () => farms.value?.find((farm) => farm.id === activeFarmId.value) ?? null,
  )

  function setActiveFarm(farmId: string) {
    activeFarmCookie.value = farmId
  }

  return {
    farms,
    farmsError,
    fetchFarms,
    refreshFarms,
    resetFarms,
    invitesChecked,
    activeFarm,
    activeFarmId,
    setActiveFarm,
  }
}
