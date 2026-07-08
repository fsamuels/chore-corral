<script setup lang="ts">
// Client-only, like FarmMap/LocationPicker/TaskMap: renders a Leaflet
// marker, which touches `window` at import time. A thin wrapper so the view
// page (a plain, SSR-rendered page) never imports `LMarker` directly.
import { LMarker } from '@vue-leaflet/vue-leaflet'

const props = defineProps<{ lat: number; lng: number }>()

const center = computed<[number, number]>(() => [props.lat, props.lng])
</script>

<template>
  <FarmMap :center="center" :zoom="18" height="240px">
    <LMarker :lat-lng="center" />
  </FarmMap>
</template>
