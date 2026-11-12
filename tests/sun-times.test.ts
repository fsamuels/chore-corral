import { afterEach, describe, expect, it } from 'vitest'
import {
  clearLastCoords,
  computeSunTimes,
  LAST_COORDS_MAX_AGE_MS,
  formatSunTimeCompact,
  isValidCoords,
  loadLastCoords,
  roundCoords,
  saveLastCoords,
} from '../app/utils/sun-times'

// Minutes between a computed time and a reference UTC instant.
function minutesOff(actual: Date, expectedIsoUtc: string): number {
  return Math.abs(actual.getTime() - Date.parse(expectedIsoUtc)) / 60_000
}

describe('computeSunTimes', () => {
  it('matches NOAA times for London on the June solstice', () => {
    // Sunrise 04:43, sunset 21:21 BST (03:43 / 20:21 UTC).
    const times = computeSunTimes(new Date(2026, 5, 21, 9), {
      lat: 51.5074,
      lng: -0.1278,
    })
    expect(times.kind).toBe('normal')
    if (times.kind !== 'normal') return
    expect(minutesOff(times.sunrise, '2026-06-21T03:43:00Z')).toBeLessThan(3)
    expect(minutesOff(times.sunset, '2026-06-21T20:21:00Z')).toBeLessThan(3)
  })

  it('handles a western longitude', () => {
    // Denver 2026-11-10: sunrise 06:39, sunset 16:48 MST (UTC-7).
    const times = computeSunTimes(new Date(2026, 10, 10, 12), {
      lat: 39.7392,
      lng: -104.9903,
    })
    expect(times.kind).toBe('normal')
    if (times.kind !== 'normal') return
    expect(minutesOff(times.sunrise, '2026-11-10T13:39:00Z')).toBeLessThan(3)
    expect(minutesOff(times.sunset, '2026-11-10T23:48:00Z')).toBeLessThan(3)
    expect(times.sunrise.getTime()).toBeLessThan(times.sunset.getTime())
  })

  it('reports polar day and polar night above the Arctic Circle', () => {
    const tromso = { lat: 69.6496, lng: 18.956 }
    expect(computeSunTimes(new Date(2026, 5, 21), tromso).kind).toBe(
      'polar-day',
    )
    expect(computeSunTimes(new Date(2026, 11, 21), tromso).kind).toBe(
      'polar-night',
    )
  })

  it('gives the same result for any time on the same calendar day', () => {
    const coords = { lat: 40, lng: -75 }
    const morning = computeSunTimes(new Date(2026, 2, 3, 0, 5), coords)
    const night = computeSunTimes(new Date(2026, 2, 3, 23, 55), coords)
    expect(morning).toEqual(night)
  })
})

describe('isValidCoords', () => {
  it('accepts in-range finite numbers', () => {
    expect(isValidCoords({ lat: 0, lng: 0 })).toBe(true)
    expect(isValidCoords({ lat: -90, lng: 180 })).toBe(true)
  })

  it('rejects anything else', () => {
    expect(isValidCoords(null)).toBe(false)
    expect(isValidCoords('x')).toBe(false)
    expect(isValidCoords({ lat: '1', lng: 2 })).toBe(false)
    expect(isValidCoords({ lat: 91, lng: 0 })).toBe(false)
    expect(isValidCoords({ lat: 0, lng: -181 })).toBe(false)
    expect(isValidCoords({ lat: Number.NaN, lng: 0 })).toBe(false)
  })
})

describe('formatSunTimeCompact', () => {
  it('drops the AM/PM marker in 12-hour locales', () => {
    expect(formatSunTimeCompact(new Date(2026, 0, 1, 6, 5), 'en-US')).toBe(
      '6:05',
    )
    expect(formatSunTimeCompact(new Date(2026, 0, 1, 16, 48), 'en-US')).toBe(
      '4:48',
    )
  })

  it('leaves 24-hour locales as they are', () => {
    expect(formatSunTimeCompact(new Date(2026, 0, 1, 16, 48), 'en-GB')).toBe(
      '16:48',
    )
  })
})

describe('last-coords cache', () => {
  const savedAt = new Date(2026, 10, 10, 8)
  afterEach(() => localStorage.clear())

  it('round-trips a coarsely rounded position', () => {
    saveLastCoords({ lat: 39.73921, lng: -104.99034 }, savedAt)
    expect(loadLastCoords(savedAt)).toEqual({ lat: 39.74, lng: -104.99 })
  })

  it('expires entries older than a day', () => {
    saveLastCoords({ lat: 1, lng: 2 }, savedAt)
    const justInside = new Date(savedAt.getTime() + LAST_COORDS_MAX_AGE_MS)
    const tooOld = new Date(justInside.getTime() + 1)
    expect(loadLastCoords(justInside)).toEqual({ lat: 1, lng: 2 })
    expect(loadLastCoords(tooOld)).toBeNull()
    // A clock set backwards doesn't make an entry "from the future" valid.
    expect(loadLastCoords(new Date(savedAt.getTime() - 1))).toBeNull()
  })

  it('returns null for missing, corrupt or untimestamped entries', () => {
    expect(loadLastCoords()).toBeNull()
    localStorage.setItem('cc-sun-coords', '{not json')
    expect(loadLastCoords()).toBeNull()
    localStorage.setItem(
      'cc-sun-coords',
      JSON.stringify({ lat: 500, lng: 0, savedAt: Date.now() }),
    )
    expect(loadLastCoords()).toBeNull()
    localStorage.setItem('cc-sun-coords', JSON.stringify({ lat: 1, lng: 2 }))
    expect(loadLastCoords()).toBeNull()
  })

  it('clears the cached position', () => {
    saveLastCoords({ lat: 1, lng: 2 }, savedAt)
    clearLastCoords()
    expect(loadLastCoords(savedAt)).toBeNull()
  })

  it('rounds to two decimals', () => {
    expect(roundCoords({ lat: 1.23456, lng: -9.87654 })).toEqual({
      lat: 1.23,
      lng: -9.88,
    })
  })
})
