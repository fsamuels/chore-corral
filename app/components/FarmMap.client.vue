<script setup lang="ts">
// Client-only (`.client.vue`): Leaflet touches `window` at import time, so
// this component must never render during SSR. Consumers get an empty
// placeholder server-side and the map after hydration.
import 'leaflet/dist/leaflet.css'
import { Icon, type LeafletMouseEvent } from 'leaflet'
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png'
import iconUrl from 'leaflet/dist/images/marker-icon.png'
import shadowUrl from 'leaflet/dist/images/marker-shadow.png'
import { LControlLayers, LMap, LTileLayer } from '@vue-leaflet/vue-leaflet'
import { tileLayers } from '~/utils/map-tiles'

// Leaflet's default marker icon resolves its image URLs relative to its CSS
// file, which breaks under Vite's bundling — point it at the bundled assets
// instead. Deleting `_getIconUrl` makes Icon.Default fall back to the plain
// options-based lookup that honors mergeOptions.
delete (Icon.Default.prototype as { _getIconUrl?: unknown })._getIconUrl
Icon.Default.mergeOptions({ iconRetinaUrl, iconUrl, shadowUrl })

const props = withDefaults(
  defineProps<{
    center: [number, number]
    zoom?: number
    height?: string
  }>(),
  { zoom: 16, height: '400px' },
)

const emit = defineEmits<{
  /** A click on the map itself (not a marker), with the clicked coordinate. */
  mapClick: [coords: { lat: number; lng: number }]
}>()

const config = useRuntimeConfig()
const layers = tileLayers(config.public.mapboxToken)

function onMapClick(event: LeafletMouseEvent) {
  // Non-map clicks (e.g. on the layer control) bubble through without a
  // latlng; ignore them.
  if (!event.latlng) return
  emit('mapClick', { lat: event.latlng.lat, lng: event.latlng.lng })
}
</script>

<template>
  <div :style="{ height: props.height }">
    <LMap
      :center="props.center"
      :zoom="props.zoom"
      :use-global-leaflet="false"
      @click="onMapClick"
    >
      <LControlLayers v-if="layers.length > 1" />
      <LTileLayer
        v-for="(layer, index) in layers"
        :key="layer.name"
        :url="layer.url"
        :attribution="layer.attribution"
        :max-zoom="layer.maxZoom"
        layer-type="base"
        :name="layer.name"
        :visible="index === 0"
      />
      <!-- Markers/popups from the consuming component. -->
      <slot />
    </LMap>
  </div>
</template>
