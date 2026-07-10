<script setup lang="ts">
// Shared location input for task create/edit: toggles between a defined
// location (a named point from `useLocations`, farm-wide) and a custom pin
// (the freeform LocationPicker flow). The two are mutually exclusive at the
// DB layer (`tasks_location_xor_pin`) and in `assertLocationXorPin`, so this
// component always emits one populated and the other explicitly null —
// switching modes clears whichever the new mode doesn't use.
import type { LocationSummary } from '~/services/locations'

export interface TaskLocationValue {
  locationId: string | null
  lat: number | null
  lng: number | null
}

const props = withDefaults(
  defineProps<{
    modelValue: TaskLocationValue
    locations: LocationSummary[]
    /** Forwarded to LocationPicker — see its doc for when to set this. */
    autoCapture?: boolean
    fallbackCenter?: { lat: number; lng: number } | null
    disabled?: boolean
  }>(),
  { autoCapture: false, fallbackCenter: null, disabled: false },
)

const emit = defineEmits<{
  'update:modelValue': [value: TaskLocationValue]
}>()

type Mode = 'defined' | 'pin'

// Initial mode follows whichever field is already populated; with neither
// set (a brand-new task) default to "defined" when the farm has any, since
// picking from a short list is the common case — otherwise fall back to the
// pin flow. Not reactive to further prop changes: the parent remounts this
// component (v-if) whenever a fresh edit session starts, which is the only
// time the initial mode should be recomputed.
const mode = ref<Mode>(
  props.modelValue.locationId !== null
    ? 'defined'
    : props.modelValue.lat !== null
      ? 'pin'
      : props.locations.length > 0
        ? 'defined'
        : 'pin',
)

const locationItems = computed(() => [
  { title: 'None', value: null as string | null },
  ...props.locations.map((location) => ({
    title: location.name,
    value: location.id as string | null,
  })),
])

const pin = computed<{ lat: number; lng: number } | null>(() =>
  props.modelValue.lat !== null && props.modelValue.lng !== null
    ? { lat: props.modelValue.lat, lng: props.modelValue.lng }
    : null,
)

function setMode(next: Mode) {
  if (mode.value === next || props.disabled) return
  mode.value = next
  emit('update:modelValue', { locationId: null, lat: null, lng: null })
}

function onDefinedSelect(locationId: string | null) {
  emit('update:modelValue', { locationId, lat: null, lng: null })
}

function onPinChange(value: { lat: number; lng: number } | null) {
  emit('update:modelValue', {
    locationId: null,
    lat: value?.lat ?? null,
    lng: value?.lng ?? null,
  })
}
</script>

<template>
  <div>
    <v-btn-toggle
      :model-value="mode"
      mandatory
      density="comfortable"
      variant="outlined"
      color="primary"
      class="mb-3"
      :disabled="disabled"
      @update:model-value="(value: Mode) => setMode(value)"
    >
      <v-btn value="defined" size="small">Defined location</v-btn>
      <v-btn value="pin" size="small">Custom pin</v-btn>
    </v-btn-toggle>

    <v-select
      v-if="mode === 'defined'"
      :model-value="modelValue.locationId"
      :items="locationItems"
      label="Location"
      density="comfortable"
      variant="outlined"
      hide-details
      :disabled="disabled"
      @update:model-value="onDefinedSelect"
    />

    <LocationPicker
      v-else
      :model-value="pin"
      :auto-capture="autoCapture"
      :fallback-center="fallbackCenter"
      :disabled="disabled"
      @update:model-value="onPinChange"
    />
  </div>
</template>
