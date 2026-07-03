import { describe, expect, it } from 'vitest'
import { tileLayers } from '../app/utils/map-tiles'

describe('tileLayers', () => {
  it('offers Mapbox satellite first (the default) plus OSM when a token is set', () => {
    const layers = tileLayers('pk.test-token')
    expect(layers.map((l) => l.name)).toEqual([
      'Satellite (Mapbox)',
      'Streets (OSM)',
    ])
    expect(layers[0]!.url).toContain('access_token=pk.test-token')
  })

  it('degrades to OSM-only without a token instead of a broken tile grid', () => {
    for (const token of [undefined, '']) {
      const layers = tileLayers(token)
      expect(layers.map((l) => l.name)).toEqual(['Streets (OSM)'])
      expect(layers[0]!.url).not.toContain('mapbox')
    }
  })
})
