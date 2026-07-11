import type { Database } from '~/types/database.types'
import {
  listLocationsWithCounts,
  type LocationSummaryWithCount,
} from '~/services/locations'

/**
 * Locations for the active farm with usage counts, for the pill/filter-link
 * display on the `/locations` page. Mirrors `useTagSummaries`'/
 * `useCategorySummaries`' shape (loading/error state, re-fetch on farm
 * switch); separate from `useLocations` since that composable's consumers
 * (task create/edit picker, the plain CRUD list) don't need counts.
 */
export function useLocationSummaries() {
  const supabase = useSupabaseClient<Database>()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no locations
  const locations = ref<LocationSummaryWithCount[] | null>(null)
  const locationsError = ref<string | null>(null)
  const loading = ref(false)

  async function fetchLocations(): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) {
      locations.value = null
      return
    }
    loading.value = true
    try {
      locations.value = await listLocationsWithCounts(supabase, farmId)
      locationsError.value = null
    } catch (error) {
      locationsError.value =
        error instanceof Error ? error.message : 'Failed to load locations'
    } finally {
      loading.value = false
    }
  }

  // Re-fetch when the user switches farms (and on initial resolution).
  watch(activeFarmId, () => {
    fetchLocations()
  })

  return {
    locations,
    locationsError,
    loading,
    fetchLocations,
  }
}
