import type { Database } from '~/types/database.types'
import {
  createLocation,
  deleteLocation,
  listLocations,
  updateLocation,
  type DeleteLocationResult,
  type LocationSummary,
} from '~/services/locations'

/**
 * Defined locations for the active farm (from `useFarms`). Plain
 * per-composable state, like `useCategories`: re-fetched whenever the active
 * farm changes.
 */
export function useLocations() {
  const supabase = useSupabaseClient<Database>()
  const user = useSupabaseUser()
  const { activeFarmId } = useFarms()

  // null = not fetched yet; [] = fetched, farm has no locations
  const locations = ref<LocationSummary[] | null>(null)
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
      locations.value = await listLocations(supabase, farmId)
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

  async function create(name: string, lat: number, lng: number): Promise<void> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) return
    const created = await createLocation(supabase, {
      farmId,
      name,
      lat,
      lng,
      actorUserId,
    })
    const next = [...(locations.value ?? []), created]
    next.sort((a, b) => a.name.localeCompare(b.name))
    locations.value = next
  }

  async function update(
    locationId: string,
    name: string,
    lat: number,
    lng: number,
  ): Promise<void> {
    const farmId = activeFarmId.value
    if (!farmId) return
    const updated = await updateLocation(supabase, {
      farmId,
      locationId,
      name,
      lat,
      lng,
    })
    const next = (locations.value ?? []).map((location) =>
      location.id === locationId ? updated : location,
    )
    next.sort((a, b) => a.name.localeCompare(b.name))
    locations.value = next
  }

  async function remove(locationId: string): Promise<DeleteLocationResult> {
    const farmId = activeFarmId.value
    const actorUserId = getActorUserId(user.value)
    if (!farmId || !actorUserId) {
      throw new Error('No active farm or signed-in user')
    }
    const result = await deleteLocation(supabase, {
      farmId,
      locationId,
      actorUserId,
    })
    if (result.deleted) {
      locations.value =
        locations.value?.filter((location) => location.id !== locationId) ??
        null
    }
    return result
  }

  return {
    locations,
    locationsError,
    loading,
    fetchLocations,
    create,
    update,
    remove,
  }
}
