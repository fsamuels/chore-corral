import type { Database } from '~/types/database.types'

const ACTIVE_FARM_COOKIE = 'cc-active-farm'

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
  const activeFarmCookie = useCookie<string | null>(ACTIVE_FARM_COOKIE, {
    default: () => null,
  })

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
    return farms.value
  }

  function resetFarms() {
    farms.value = null
    farmsError.value = null
    activeFarmCookie.value = null
  }

  const activeFarmId = computed(() =>
    resolveActiveFarmId(farms.value ?? [], activeFarmCookie.value),
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
    resetFarms,
    activeFarm,
    activeFarmId,
    setActiveFarm,
  }
}
