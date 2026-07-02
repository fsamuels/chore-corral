export interface FarmSummary {
  id: string
  name: string
}

/**
 * Pick the active farm: the saved selection if it's still one of the user's
 * farms, otherwise the first farm, otherwise none.
 */
export function resolveActiveFarmId(
  farms: FarmSummary[],
  savedFarmId: string | null | undefined,
): string | null {
  if (savedFarmId && farms.some((farm) => farm.id === savedFarmId)) {
    return savedFarmId
  }
  return farms[0]?.id ?? null
}
