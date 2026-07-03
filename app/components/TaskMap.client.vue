<script setup lang="ts">
// Client-only, like FarmMap and LocationPicker: renders Leaflet markers,
// which touch `window` at import time.
import { LMarker, LPopup } from '@vue-leaflet/vue-leaflet'
import { latLngBounds, type Map as LeafletMap } from 'leaflet'
import type { TaskPriority, TaskStatus, TaskSummary } from '~/services/tasks'

const props = withDefaults(
  defineProps<{
    tasks: TaskSummary[]
    /** Map center before any pins exist (or while pins are still loading). */
    fallbackCenter: { lat: number; lng: number } | null
    height?: string
  }>(),
  { height: '100%' },
)

const emit = defineEmits<{
  open: [taskId: string]
}>()

const priorityDisplay: Record<TaskPriority, { color: string; label: string }> =
  {
    urgent: { color: 'error', label: 'Urgent' },
    soon: { color: 'warning', label: 'Soon' },
    whenever: { color: '', label: 'Whenever' },
  }

const statusDisplay: Record<TaskStatus, string> = {
  not_started: 'Not started',
  in_progress: 'In progress',
  done: 'Done',
}

// Map center/zoom before pins load or fit — the farm's default center when
// known, otherwise a world view. Once the map is ready, fitBounds (below)
// takes over whenever there are pins to fit.
const FALLBACK_ZOOM = 15
const center = computed<[number, number]>(() =>
  props.fallbackCenter
    ? [props.fallbackCenter.lat, props.fallbackCenter.lng]
    : [20, 0],
)
const zoom = computed(() => (props.fallbackCenter ? FALLBACK_ZOOM : 3))

// The caller is expected to pre-filter to located tasks, but `TaskSummary`
// still types lat/lng as nullable — narrow here so the template can bind
// straight to Leaflet's LatLngExpression without `!` assertions, and so a
// stray unlocated task is silently dropped rather than crashing the map.
const pins = computed(() =>
  props.tasks.filter(
    (task): task is TaskSummary & { lat: number; lng: number } =>
      task.lat !== null && task.lng !== null,
  ),
)

function onReady(map: LeafletMap) {
  if (pins.value.length === 0) return
  const bounds = latLngBounds(
    pins.value.map((task) => [task.lat, task.lng] as [number, number]),
  )
  map.fitBounds(bounds, { padding: [40, 40], maxZoom: 17 })
}

function openTask(taskId: string) {
  emit('open', taskId)
}
</script>

<template>
  <FarmMap
    :center="center"
    :zoom="zoom"
    :height="props.height"
    @ready="onReady"
  >
    <LMarker
      v-for="task in pins"
      :key="task.id"
      :lat-lng="[task.lat, task.lng]"
    >
      <LPopup>
        <div class="font-weight-bold">{{ task.title }}</div>
        <div class="text-body-2 mb-2">
          {{ priorityDisplay[task.priority].label }} &middot;
          {{ statusDisplay[task.status] }}
        </div>
        <v-btn size="small" color="primary" @click="openTask(task.id)">
          Open task
        </v-btn>
      </LPopup>
    </LMarker>
  </FarmMap>
</template>
