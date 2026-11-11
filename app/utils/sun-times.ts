/**
 * Sunrise/sunset for a given place and local calendar day, computed on-device
 * with the standard "sunrise equation" (NOAA-style low-precision solar
 * position). Accurate to about a minute at non-polar latitudes, which is all a
 * glanceable home-screen pill needs — and it avoids a network dependency on a
 * third-party sun-times API.
 */

export interface Coords {
  lat: number
  lng: number
}

export type SunTimes =
  | { kind: 'normal'; sunrise: Date; sunset: Date }
  // The sun never sets / never rises on this day at this latitude.
  | { kind: 'polar-day' }
  | { kind: 'polar-night' }

const MS_PER_DAY = 86_400_000
const JULIAN_UNIX_EPOCH = 2_440_587.5
const J2000 = 2_451_545
const OBLIQUITY = 23.4397
// Apparent sunrise/sunset: centre of the disc 0.833° below the horizon
// (refraction plus the sun's apparent radius).
const HORIZON_ALTITUDE = -0.833

const rad = (deg: number) => (deg * Math.PI) / 180
const deg = (r: number) => (r * 180) / Math.PI
const mod360 = (x: number) => ((x % 360) + 360) % 360

function julianToDate(julian: number): Date {
  return new Date((julian - JULIAN_UNIX_EPOCH) * MS_PER_DAY)
}

export function isValidCoords(value: unknown): value is Coords {
  if (!value || typeof value !== 'object') return false
  const { lat, lng } = value as Record<string, unknown>
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  )
}

/**
 * Sun times for the calendar day that `day` falls on in the device's time
 * zone, at `coords` (longitude east-positive).
 */
export function computeSunTimes(day: Date, coords: Coords): SunTimes {
  // Days since J2000 for this calendar date (at 12:00 UTC, so the rounding
  // can't slip a day), then shifted to local mean solar noon by longitude.
  const noonUtc = Date.UTC(day.getFullYear(), day.getMonth(), day.getDate(), 12)
  // 0.0008 days is the reference formula's correction for leap seconds and
  // terrestrial time.
  const n = Math.round(
    noonUtc / MS_PER_DAY + JULIAN_UNIX_EPOCH - J2000 + 0.0008,
  )
  const meanSolarNoon = n - coords.lng / 360

  const meanAnomaly = mod360(357.5291 + 0.98560028 * meanSolarNoon)
  const m = rad(meanAnomaly)
  const center =
    1.9148 * Math.sin(m) + 0.02 * Math.sin(2 * m) + 0.0003 * Math.sin(3 * m)
  const eclipticLongitude = rad(mod360(meanAnomaly + center + 180 + 102.9372))
  const transit =
    J2000 +
    meanSolarNoon +
    0.0053 * Math.sin(m) -
    0.0069 * Math.sin(2 * eclipticLongitude)

  const sinDeclination = Math.sin(eclipticLongitude) * Math.sin(rad(OBLIQUITY))
  const cosDeclination = Math.cos(Math.asin(sinDeclination))
  const phi = rad(coords.lat)
  const cosHourAngle =
    (Math.sin(rad(HORIZON_ALTITUDE)) - Math.sin(phi) * sinDeclination) /
    (Math.cos(phi) * cosDeclination)

  if (cosHourAngle > 1) return { kind: 'polar-night' }
  if (cosHourAngle < -1) return { kind: 'polar-day' }

  const halfDay = deg(Math.acos(cosHourAngle)) / 360
  return {
    kind: 'normal',
    sunrise: julianToDate(transit - halfDay),
    sunset: julianToDate(transit + halfDay),
  }
}

/**
 * "6:42": the time without its AM/PM marker, in the device's locale and time
 * zone. The sunrise/sunset icon beside it already says morning vs. evening. 24-hour locales
 * are unchanged ("18:42").
 */
export function formatSunTimeCompact(date: Date, locale?: string): string {
  return new Intl.DateTimeFormat(locale, { hour: 'numeric', minute: '2-digit' })
    .formatToParts(date)
    .filter((part) => part.type !== 'dayPeriod')
    .map((part) => part.value)
    .join('')
    .trim()
}

// Last device position, so the pill can render immediately on the next visit
// instead of waiting on a fresh fix. Coarse-rounded (sun times don't need
// more than ~1 km precision, and there's no reason to persist an exact fix),
// and expired after a day so a trip doesn't leave stale times behind.
const LAST_COORDS_KEY = 'cc-sun-coords'
export const LAST_COORDS_MAX_AGE_MS = MS_PER_DAY

function roundCoord(value: number): number {
  return Math.round(value * 100) / 100
}

export function roundCoords(coords: Coords): Coords {
  return { lat: roundCoord(coords.lat), lng: roundCoord(coords.lng) }
}

export function loadLastCoords(now: Date = new Date()): Coords | null {
  try {
    const raw = localStorage.getItem(LAST_COORDS_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as { savedAt?: unknown } & Partial<Coords>
    const coords = { lat: parsed.lat, lng: parsed.lng }
    if (typeof parsed.savedAt !== 'number' || !isValidCoords(coords)) {
      return null
    }
    const age = now.getTime() - parsed.savedAt
    return age >= 0 && age <= LAST_COORDS_MAX_AGE_MS ? coords : null
  } catch {
    return null
  }
}

export function saveLastCoords(coords: Coords, now: Date = new Date()): void {
  try {
    localStorage.setItem(
      LAST_COORDS_KEY,
      JSON.stringify({ ...roundCoords(coords), savedAt: now.getTime() }),
    )
  } catch {
    // Storage unavailable (private mode, quota) — just skip the cache.
  }
}

/** Forget the cached position (location denied, or sign-out). */
export function clearLastCoords(): void {
  try {
    localStorage.removeItem(LAST_COORDS_KEY)
  } catch {
    // Storage unavailable — nothing to clear.
  }
}
