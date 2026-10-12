import { describe, expect, it } from 'vitest'
import { IN_FILTER_CHUNK_SIZE, chunk } from '../app/utils/chunk'

describe('chunk', () => {
  it('splits into consecutive slices of the default size, the last one partial', () => {
    const items = Array.from({ length: 250 }, (_, i) => i)
    const chunks = chunk(items)
    expect(chunks.map((c) => c.length)).toEqual([
      IN_FILTER_CHUNK_SIZE,
      IN_FILTER_CHUNK_SIZE,
      50,
    ])
    expect(chunks.flat()).toEqual(items)
  })

  it('returns no chunks for an empty list', () => {
    expect(chunk([])).toEqual([])
  })

  it('honors an explicit size', () => {
    expect(chunk(['a', 'b', 'c'], 2)).toEqual([['a', 'b'], ['c']])
  })
})
