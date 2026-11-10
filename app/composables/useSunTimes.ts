import type { MaybeRefOrGetter } from 'vue'
import {
  clearLastCoords,
  computeSunTimes,
  isValidCoords,
  loadLastCoords,
  saveLastCoords,
  type Coords,
  type SunTimes,
} from '~/utils/sun-times'

type LocationPermission = 'granted' | 'prompt' | 'denied' | 'unsupported'

const DAY_CHECK_INTERVAL_MS = 60_000

/**
 * Today's sunrise/sunset for where the user is. Uses the device's position
 * when location access is already granted, and otherwise falls back to
 * `fallback` (the active farm's default coordinates). It never brings up the
 * browser's location prompt on its own — a decorative pill shouldn't — so
 * when access hasn't been decided yet, `canUseDeviceLocation` is true and the
 * caller offers a tap that calls `requestDeviceLocation()`.
 *
 * Client-only: on the server, and until a position is known, `sunTimes` is
 * null and the caller renders nothing.
 */
export function useSunTimes(fallback: MaybeRefOrGetter<Coords | null>) {
  const deviceCoords = ref<Coords | null>(null)
  const permission = ref<LocationPermission>('unsupported')
  const locating = ref(false)
  const today = ref<Date | null>(null)
  let disposed = false
  let dayTimer: ReturnType<typeof setInterval> | undefined

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

  // Offer "use my location" only while the browser would still ask — not
  // once it's granted (we already use it) or denied (asking is a no-op).
  const canUseDeviceLocation = computed(
    () => !deviceCoords.value && permission.value === 'prompt',
  )

  // A home screen left open across midnight (a wall tablet, an installed
  // PWA) rolls over to the new day: checked every minute and on refocus.
  function refreshDay() {
    const now = new Date()
    if (!today.value || today.value.toDateString() !== now.toDateString()) {
      today.value = now
    }
  }

  function onVisibilityChange() {
    if (document.visibilityState === 'visible') refreshDay()
  }

  function forgetDevicePosition() {
    deviceCoords.value = null
    clearLastCoords()
  }

  function requestDeviceLocation() {
    if (!('geolocation' in navigator) || locating.value) return
    locating.value = true
    navigator.geolocation.getCurrentPosition(
      (position) => {
        if (disposed) return
        locating.value = false
        permission.value = 'granted'
        const fix = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        }
        deviceCoords.value = fix
        saveLastCoords(fix)
      },
      (error) => {
        if (disposed) return
        locating.value = false
        // Denied: stop using (and stop storing) the user's position. Any
        // other failure (no fix, timeout) keeps a still-fresh cached one.
        if (error.code === error.PERMISSION_DENIED) {
          permission.value = 'denied'
          forgetDevicePosition()
        }
      },
      // Sun times barely move over tens of km or an hour, so a coarse,
      // cached fix is fine and avoids spinning up GPS on every home visit.
      { enableHighAccuracy: false, timeout: 15_000, maximumAge: 3_600_000 },
    )
  }

  async function readPermission(): Promise<LocationPermission> {
    if (!('geolocation' in navigator)) return 'unsupported'
    try {
      const status = await navigator.permissions.query({ name: 'geolocation' })
      return status.state
    } catch {
      // No Permissions API (older Safari): we can't tell without asking, so
      // treat it as undecided and leave the request to the user's tap.
      return 'prompt'
    }
  }

  onMounted(async () => {
    refreshDay()
    dayTimer = setInterval(refreshDay, DAY_CHECK_INTERVAL_MS)
    document.addEventListener('visibilitychange', onVisibilityChange)

    const state = await readPermission()
    if (disposed) return
    permission.value = state
    if (state === 'granted') {
      deviceCoords.value = loadLastCoords()
      requestDeviceLocation()
    } else if (state === 'denied' || state === 'unsupported') {
      forgetDevicePosition()
    }
  })

  onBeforeUnmount(() => {
    disposed = true
    clearInterval(dayTimer)
    document.removeEventListener('visibilitychange', onVisibilityChange)
  })

  return { sunTimes, canUseDeviceLocation, locating, requestDeviceLocation }
}
