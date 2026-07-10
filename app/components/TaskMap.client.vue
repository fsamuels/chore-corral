<script setup lang="ts">
// Client-only, like FarmMap and LocationPicker: renders Leaflet markers,
// which touch `window` at import time.
import { LMarker, LPopup } from '@vue-leaflet/vue-leaflet'
import {
  divIcon,
  latLngBounds,
  type Icon,
  type Map as LeafletMap,
} from 'leaflet'
import type { TaskPriority, TaskStatus, TaskSummary } from '~/services/tasks'
import type { LocationSummary } from '~/services/locations'

const props = withDefaults(
  defineProps<{
    tasks: TaskSummary[]
    /**
     * The farm's defined locations, rendered as distinct labeled markers so
     * named spots (Shop, Front Barn, ...) show up even with no tasks pinned
     * there. Callers resolve a task's `location_id` to lat/lng themselves
     * before passing it in `tasks` — this component only draws the location
     * markers, it doesn't cross-reference task.location_id.
     */
    locations?: LocationSummary[]
    /** Map center before any pins exist (or while pins are still loading). */
    fallbackCenter: { lat: number; lng: number } | null
    height?: string
  }>(),
  { height: '100%', locations: () => [] },
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
// takes over whenever there are pins to fit. Both this and fitBounds's
// maxZoom below are set 4 levels higher/tighter than the previous values
// (13/15) — the prior pass zoomed out in the wrong direction.
const FALLBACK_ZOOM = 17
const center = computed<[number, number]>(() =>
  props.fallbackCenter
    ? [props.fallbackCenter.lat, props.fallbackCenter.lng]
    : [20, 0],
)
const zoom = computed(() => (props.fallbackCenter ? FALLBACK_ZOOM : 3))

// The caller is expected to pre-filter/resolve to located tasks (including
// resolving `location_id` tasks to their location's coords), but
// `TaskSummary` still types lat/lng as nullable — narrow here so the
// template can bind straight to Leaflet's LatLngExpression without `!`
// assertions, and so a stray unlocated task is silently dropped rather than
// crashing the map.
const locatedTasks = computed(() =>
  props.tasks.filter(
    (task): task is TaskSummary & { lat: number; lng: number } =>
      task.lat !== null && task.lng !== null,
  ),
)

// Multiple tasks can legitimately share one defined location's exact
// coordinates and would otherwise render as a single indistinguishable
// marker. Rather than building real clustering, tasks sharing a coordinate
// (rounded to ~1m) get spread in a small deterministic circle around the
// shared point, keyed on their position within the group — same input order
// always produces the same layout.
const JITTER_RADIUS = 0.00006
function coordKey(lat: number, lng: number): string {
  return `${lat.toFixed(5)},${lng.toFixed(5)}`
}

const pins = computed(() => {
  const groups = new Map<
    string,
    (TaskSummary & { lat: number; lng: number })[]
  >()
  for (const task of locatedTasks.value) {
    const key = coordKey(task.lat, task.lng)
    const group = groups.get(key)
    if (group) group.push(task)
    else groups.set(key, [task])
  }

  const result: { task: TaskSummary; lat: number; lng: number }[] = []
  for (const group of groups.values()) {
    if (group.length === 1) {
      const task = group[0]!
      result.push({ task, lat: task.lat, lng: task.lng })
      continue
    }
    group.forEach((task, index) => {
      const angle = (2 * Math.PI * index) / group.length
      result.push({
        task,
        lat: task.lat + JITTER_RADIUS * Math.sin(angle),
        lng: task.lng + JITTER_RADIUS * Math.cos(angle),
      })
    })
  }
  return result
})

// Labeled marker for a defined location — visually distinct from the
// default Leaflet pin used for tasks (a small dark flag with the name
// alongside, rather than the standard blue teardrop).
// vue-leaflet's LMarker types its `icon` prop as Leaflet's `Icon`, but
// `divIcon()` returns the sibling `DivIcon` class — both implement the same
// runtime interface Leaflet actually uses (they share the `Icon` base), so
// this cast is safe; TypeScript just can't see the structural overlap.
function locationIcon(name: string): Icon {
  return divIcon({
    className: 'cc-location-marker',
    html: `<span class="cc-location-marker__dot"></span><span class="cc-location-marker__label">${escapeHtml(name)}</span>`,
    iconAnchor: [6, 6],
  }) as unknown as Icon
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

function onReady(map: LeafletMap) {
  const points: [number, number][] = [
    ...pins.value.map((pin) => [pin.lat, pin.lng] as [number, number]),
    ...props.locations.map((loc) => [loc.lat, loc.lng] as [number, number]),
  ]
  if (points.length === 0) return
  const bounds = latLngBounds(points)
  map.fitBounds(bounds, { padding: [40, 40], maxZoom: 19 })
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
      v-for="location in props.locations"
      :key="`location-${location.id}`"
      :lat-lng="[location.lat, location.lng]"
      :icon="locationIcon(location.name)"
    >
      <LPopup>
        <div class="font-weight-bold">{{ location.name }}</div>
      </LPopup>
    </LMarker>

    <LMarker
      v-for="pin in pins"
      :key="pin.task.id"
      :lat-lng="[pin.lat, pin.lng]"
    >
      <LPopup>
        <div class="font-weight-bold">{{ pin.task.title }}</div>
        <div class="text-body-2 mb-2">
          {{ priorityDisplay[pin.task.priority].label }} &middot;
          {{ statusDisplay[pin.task.status] }}
        </div>
        <v-btn size="small" color="primary" @click="openTask(pin.task.id)">
          Open task
        </v-btn>
      </LPopup>
    </LMarker>
  </FarmMap>
</template>

<style>
/* Global (not scoped): Leaflet mounts divIcon markup outside this
   component's DOM tree, so scoped attribute selectors would never match. */
.cc-location-marker {
  display: flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  pointer-events: none;
}

.cc-location-marker__dot {
  display: inline-block;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--cc-ink, #2b2118);
  border: 2px solid #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
}

.cc-location-marker__label {
  background: var(--cc-ink, #2b2118);
  color: #fff;
  font-family: var(--cc-font-sans, sans-serif);
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}
</style>
