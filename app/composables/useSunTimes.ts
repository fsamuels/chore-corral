import type { MaybeRefOrGetter } from 'vue'
import {
  computeSunTimes,
  isValidCoords,
  loadLastCoords,
  saveLastCoords,
  type Coords,
  type SunTimes,
} from '~/utils/sun-times'

/**
 * Today's sunrise/sunset for where the user is. Prefers the device's position
 * (asked for once on mount; the browser remembers the answer), and falls back
 * to `fallback` — the active farm's default coordinates — when location is
 * unavailable or denied. Client-only: on the server, and until a position is
 * known, `sunTimes` is null and the caller renders nothing.
 */
export function useSunTimes(fallback: MaybeRefOrGetter<Coords | null>) {
  const deviceCoords = ref<Coords | null>(null)
  // Bumped when the page regains focus, so a home screen left open across
  // midnight (an installed PWA, a backgrounded tab) rolls over to the new day.
  const today = ref<Date | null>(null)

  const coords = computed<Coords | null>(() => {
    if (deviceCoords.value) return deviceCoords.value
    const farm = toValue(fallback)
    return isValidCoords(farm) ? farm : null
  })

  const sunTimes = computed<SunTimes | null>(() =>
    today.value && coords.value
      ? computeSunTimes(today.value, coords.value)
      : null,
  )

  function refreshDay() {
    const now = new Date()
    if (!today.value || today.value.toDateString() !== now.toDateString()) {
      today.value = now
    }
  }

  function onVisibilityChange() {
    if (document.visibilityState === 'visible') refreshDay()
  }

  onMounted(() => {
    refreshDay()
    deviceCoords.value = loadLastCoords()
    document.addEventListener('visibilitychange', onVisibilityChange)

    if (!('geolocation' in navigator)) return
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const fix = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        }
        deviceCoords.value = fix
        saveLastCoords(fix)
      },
      // Denied or no fix: keep the cached position if there is one, else the
      // farm fallback takes over via `coords`.
      () => {},
      // Sun times barely move over tens of km or an hour, so a coarse,
      // cached fix is fine and avoids spinning up GPS on every home visit.
      { enableHighAccuracy: false, timeout: 15_000, maximumAge: 3_600_000 },
    )
  })

  onBeforeUnmount(() => {
    document.removeEventListener('visibilitychange', onVisibilityChange)
  })

  return { sunTimes }
}
