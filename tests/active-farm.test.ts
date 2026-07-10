import { describe, expect, it } from 'vitest'
import { resolveActiveFarmId } from '../app/utils/active-farm'

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
