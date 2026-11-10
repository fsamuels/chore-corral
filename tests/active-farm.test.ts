import { describe, expect, it } from 'vitest'
import {
  farmCenter,
  farmSwitchFromQuery,
  resolveActiveFarmId,
} from '../app/utils/active-farm'

const farms = [
  { id: 'farm-a', name: 'Reign Cloud Ranch' },
  { id: 'farm-b', name: "Clarkson's Farm" },
]

describe('resolveActiveFarmId', () => {
  it('keeps the saved farm when it is still one of the user farms', () => {
    expect(resolveActiveFarmId(farms, 'farm-b')).toBe('farm-b')
  })

  it('falls back to the first farm when nothing is saved', () => {
    expect(resolveActiveFarmId(farms, null)).toBe('farm-a')
  })

  it('falls back to the first farm when the saved farm is no longer a membership', () => {
    expect(resolveActiveFarmId(farms, 'farm-gone')).toBe('farm-a')
  })

  it('returns null when the user has no farms', () => {
    expect(resolveActiveFarmId([], 'farm-a')).toBeNull()
  })

  it('falls back to the most recently active farm when nothing is saved', () => {
    expect(resolveActiveFarmId(farms, null, 'farm-b')).toBe('farm-b')
  })

  it('falls back to the most recently active farm when the saved farm is no longer a membership', () => {
    expect(resolveActiveFarmId(farms, 'farm-gone', 'farm-b')).toBe('farm-b')
  })

  it('prefers the saved farm over the most recently active farm', () => {
    expect(resolveActiveFarmId(farms, 'farm-a', 'farm-b')).toBe('farm-a')
  })

  it('falls back to the first farm when the most recently active farm is not a membership', () => {
    expect(resolveActiveFarmId(farms, null, 'farm-gone')).toBe('farm-a')
  })

  it('falls back to the first farm when neither a saved nor a recent farm is known', () => {
    expect(resolveActiveFarmId(farms, null, null)).toBe('farm-a')
  })
})

describe('farmSwitchFromQuery', () => {
  it('switches to the query farm when it is a membership and not already active', () => {
    expect(farmSwitchFromQuery('farm-b', farms, 'farm-a')).toBe('farm-b')
  })

  it('returns null when there is no query param', () => {
    expect(farmSwitchFromQuery(undefined, farms, 'farm-a')).toBeNull()
  })

  it('returns null for a non-string query value', () => {
    expect(farmSwitchFromQuery(['farm-b'], farms, 'farm-a')).toBeNull()
  })

  it('returns null when the query farm is already active', () => {
    expect(farmSwitchFromQuery('farm-a', farms, 'farm-a')).toBeNull()
  })

  it('returns null when the query farm is not one of the user’s farms', () => {
    expect(farmSwitchFromQuery('farm-foreign', farms, 'farm-a')).toBeNull()
  })

  it('switches even when there is no currently active farm', () => {
    expect(farmSwitchFromQuery('farm-b', farms, null)).toBe('farm-b')
  })
})

describe('farmCenter', () => {
  it('returns the default centre when both coordinates are set', () => {
    expect(farmCenter({ default_lat: 39.7, default_lng: -105 })).toEqual({
      lat: 39.7,
      lng: -105,
    })
  })

  it('treats 0 as a real coordinate', () => {
    expect(farmCenter({ default_lat: 0, default_lng: 0 })).toEqual({
      lat: 0,
      lng: 0,
    })
  })

  it('returns null when unset or there is no farm', () => {
    expect(farmCenter({ default_lat: 1, default_lng: null })).toBeNull()
    expect(farmCenter({ default_lat: null, default_lng: 1 })).toBeNull()
    expect(farmCenter(null)).toBeNull()
    expect(farmCenter(undefined)).toBeNull()
  })
})
