import { describe, expect, it } from 'vitest'
import { computeResizedDimensions } from '../app/utils/photo-compression'

describe('computeResizedDimensions', () => {
  it('returns the original dimensions unchanged when already under the max edge', () => {
    const result = computeResizedDimensions(800, 600, 1600)

    expect(result).toEqual({ width: 800, height: 600 })
  })

  it('scales down a landscape image so its width matches the max edge', () => {
    const result = computeResizedDimensions(3200, 1600, 1600)

    expect(result).toEqual({ width: 1600, height: 800 })
  })

  it('scales down a portrait image so its height matches the max edge', () => {
    const result = computeResizedDimensions(1600, 3200, 1600)

    expect(result).toEqual({ width: 800, height: 1600 })
  })

  it('scales down a square image so both edges match the max edge', () => {
    const result = computeResizedDimensions(2000, 2000, 1600)

    expect(result).toEqual({ width: 1600, height: 1600 })
  })

  it('leaves dimensions unchanged when the longest edge is exactly the max edge', () => {
    const result = computeResizedDimensions(1600, 1200, 1600)

    expect(result).toEqual({ width: 1600, height: 1200 })
  })
})
