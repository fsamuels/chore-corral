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
