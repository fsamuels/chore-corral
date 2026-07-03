// Centralized tile-provider configuration (per ARCHITECTURE.md): swapping or
// comparing providers (Mapbox vs. Esri vs. OSM) should only ever touch this
// file, never the map components.

export interface TileLayerConfig {
  /** Layer-control label. */
  name: string
  /** XYZ tile URL template. */
  url: string
  attribution: string
  maxZoom: number
}

const OSM_LAYER: TileLayerConfig = {
  name: 'Streets (OSM)',
  url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution:
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  maxZoom: 19,
}

/**
 * Base layers for the layer control, default first: Mapbox Satellite Streets
 * (hybrid — imagery + road/label overlay) when a token is configured, with
 * plain OSM streets as the toggle alternative. Without a token (e.g. a dev
 * setup without a Mapbox account) the map degrades to OSM-only rather than
 * rendering a broken tile grid.
 */
export function tileLayers(mapboxToken: string | undefined): TileLayerConfig[] {
  if (!mapboxToken) return [OSM_LAYER]
  return [
    {
      name: 'Satellite (Mapbox)',
      // The `/256/` path segment requests 256px tiles, matching Leaflet's
      // default tile size — no zoomOffset gymnastics needed.
      url: `https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}?access_token=${mapboxToken}`,
      attribution:
        '&copy; <a href="https://www.mapbox.com/about/maps/">Mapbox</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
      maxZoom: 22,
    },
    OSM_LAYER,
  ]
}
