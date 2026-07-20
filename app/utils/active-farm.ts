export interface FarmSummary {
  id: string
  name: string
  /** Default map center, manually set at farm creation (may be unset). */
  default_lat: number | null
  default_lng: number | null
}

/**
 * Pick the active farm: the saved selection if it's still one of the user's
 * farms; otherwise the farm with the most recent task activity, if known;
 * otherwise the first farm; otherwise none.
 */
export function resolveActiveFarmId(
  farms: Pick<FarmSummary, 'id'>[],
  savedFarmId: string | null | undefined,
  mostRecentFarmId?: string | null,
): string | null {
  if (savedFarmId && farms.some((farm) => farm.id === savedFarmId)) {
    return savedFarmId
  }
  if (mostRecentFarmId && farms.some((farm) => farm.id === mostRecentFarmId)) {
    return mostRecentFarmId
  }
  return farms[0]?.id ?? null
}

/**
 * Whether a deep link's `?farm=` query param (e.g. a reminder push
 * notification's url — see supabase/functions/send-reminders) should
 * trigger a farm switch: present, a real membership, and not already the
 * active farm. Returns the farm id to switch to, or null to leave the
 * active farm as-is (including when the query id isn't one of the user's
 * farms — a bogus/foreign id is ignored rather than switched to).
 */
export function farmSwitchFromQuery(
  queryFarmId: unknown,
  farms: Pick<FarmSummary, 'id'>[],
  activeFarmId: string | null,
): string | null {
  if (typeof queryFarmId !== 'string' || queryFarmId.length === 0) return null
  if (queryFarmId === activeFarmId) return null
  if (!farms.some((farm) => farm.id === queryFarmId)) return null
  return queryFarmId
}
