<script setup lang="ts">
// Client-only, like FarmMap: uses Leaflet (via the vue-leaflet marker) and
// the browser Geolocation API, neither of which exists during SSR. Both task
// dialogs mount this fresh each time they open (their content is v-if'd), so
// per-open state like the GPS error resets naturally.
import { LMarker } from '@vue-leaflet/vue-leaflet'
import type { LatLng } from 'leaflet'

const props = withDefaults(
  defineProps<{
    modelValue: { lat: number; lng: number } | null
    /**
     * Attempt GPS capture as soon as the picker appears (SPEC: task creation
     * auto-captures the device position). Off for editing, where overwriting
     * an existing pin with wherever the editor happens to be standing would
     * be wrong.
     */
    autoCapture?: boolean
    /** Map center before any pin exists — the farm's default center. */
    fallbackCenter?: { lat: number; lng: number } | null
    disabled?: boolean
  }>(),
  { autoCapture: false, fallbackCenter: null, disabled: false },
)

const emit = defineEmits<{
  'update:modelValue': [value: { lat: number; lng: number } | null]
}>()

const pin = computed(() => props.modelValue)

// True once the user has chosen manual placement, so the map shows before
// any pin exists.
const placing = ref(false)
const locating = ref(false)
const geoError = ref<string | null>(null)

const showMap = computed(() => pin.value !== null || placing.value)

// The map center is deliberately plain state, not computed from the pin:
// recentering on every drag tick would yank the map around mid-drag. It
// moves only on mount and on a GPS fix.
const FALLBACK_ZOOM = 17
const PIN_ZOOM = 19
const center = ref<[number, number]>([20, 0])
const zoom = ref(3)

function recenter(coords: { lat: number; lng: number }, toZoom: number) {
  center.value = [coords.lat, coords.lng]
  zoom.value = toZoom
}

if (pin.value) {
  recenter(pin.value, PIN_ZOOM)
} else if (props.fallbackCenter) {
  recenter(props.fallbackCenter, FALLBACK_ZOOM)
}

onMounted(() => {
  if (props.autoCapture && !pin.value) capture()
})

function capture() {
  geoError.value = null
  if (!('geolocation' in navigator)) {
    geoError.value =
      'Location is not available on this device — place the pin manually, or save without a location.'
    placing.value = true
    return
  }
  locating.value = true
  navigator.geolocation.getCurrentPosition(
    (position) => {
      locating.value = false
      const coords = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      }
      recenter(coords, PIN_ZOOM)
      emit('update:modelValue', coords)
    },
    (error) => {
      locating.value = false
      placing.value = true
      geoError.value =
        error.code === error.PERMISSION_DENIED
          ? 'Location permission was denied — place the pin manually, or save without a location.'
          : "Couldn't get a GPS fix — place the pin manually, or save without a location."
    },
    { enableHighAccuracy: true, timeout: 10_000, maximumAge: 30_000 },
  )
}

function onMapClick(coords: { lat: number; lng: number }) {
  if (props.disabled) return
  geoError.value = null
  emit('update:modelValue', coords)
}

function onMarkerMoved(latLng: LatLng) {
  emit('update:modelValue', { lat: latLng.lat, lng: latLng.lng })
}

function removePin() {
  placing.value = false
  geoError.value = null
  emit('update:modelValue', null)
}
</script>

<template>
  <div>
    <div class="d-flex align-center flex-wrap ga-2 mb-2">
      <v-btn
        size="small"
        variant="tonal"
        prepend-icon="mdi-crosshairs-gps"
        :loading="locating"
        :disabled="disabled"
        @click="capture"
      >
        Use my location
      </v-btn>
      <v-btn
        v-if="!showMap"
        size="small"
        variant="text"
        :disabled="disabled || locating"
        @click="placing = true"
      >
        Place pin manually
      </v-btn>
      <v-btn
        v-if="pin"
        size="small"
        variant="text"
        color="error"
        :disabled="disabled"
        @click="removePin"
      >
        Remove location
      </v-btn>
    </div>

    <v-alert
      v-if="geoError"
      type="warning"
      variant="tonal"
      density="compact"
      class="mb-2"
    >
      {{ geoError }}
    </v-alert>

    <template v-if="showMap">
      <FarmMap
        :center="center"
        :zoom="zoom"
        height="260px"
        @map-click="onMapClick"
      >
        <LMarker
          v-if="pin"
          :lat-lng="[pin.lat, pin.lng]"
          :draggable="!disabled"
          @update:lat-lng="onMarkerMoved"
        />
      </FarmMap>
      <p class="text-caption text-medium-emphasis mt-1 mb-0">
        {{
          pin
            ? 'Tap the map or drag the pin to adjust.'
            : 'Tap the map to place the pin.'
        }}
      </p>
    </template>
  </div>
</template>
