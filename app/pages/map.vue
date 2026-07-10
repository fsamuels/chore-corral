<script setup lang="ts">
import type { TaskSummary } from '~/services/tasks'

const { fetchFarms, activeFarm, farmsError } = useFarms()
const { tasks, tasksError, loading, fetchTasks } = useTasks()
const { locations, fetchLocations } = useLocations()

// Same fetch order as tasks/index.vue: farms first so the active farm resolves
// during SSR, then that farm's tasks (and its defined locations).
await fetchFarms()
await fetchTasks()
await fetchLocations()

// Tasks with a freeform pin already carry lat/lng; tasks with a defined
// location only carry `location_id`, so resolve those to the location's
// coords here before handing everything to TaskMap (which just draws
// whatever lat/lng it's given — it doesn't know about location_id at all).
const locatedTasks = computed<TaskSummary[]>(() => {
  const byId = new Map((locations.value ?? []).map((l) => [l.id, l]))
  const resolved: TaskSummary[] = []
  for (const task of tasks.value ?? []) {
    if (task.lat !== null && task.lng !== null) {
      resolved.push(task)
      continue
    }
    if (task.location_id !== null) {
      const location = byId.get(task.location_id)
      if (location) {
        resolved.push({ ...task, lat: location.lat, lng: location.lng })
      }
    }
  }
  return resolved
})

// Map starting point before any pins are fit — the farm's default center
// (SPEC: manually set at farm creation) when known.
const farmCenter = computed(() => {
  const farm = activeFarm.value
  return farm?.default_lat != null && farm?.default_lng != null
    ? { lat: farm.default_lat, lng: farm.default_lng }
    : null
})

function onOpen(taskId: string) {
  navigateTo(`/tasks/${taskId}`)
}
</script>

<template>
  <v-container>
    <v-alert
      v-if="farmsError"
      type="error"
      variant="tonal"
      title="Couldn't load your farms"
      class="mb-4"
    >
      {{ farmsError }} — try reloading; if this persists, the database may not
      be reachable.
    </v-alert>
    <template v-else-if="activeFarm">
      <div class="mb-4">
        <h1 class="text-h4 mb-1">Map</h1>
        <p class="cc-eyebrow">{{ activeFarm.name }}</p>
      </div>

      <v-alert
        v-if="tasksError"
        type="error"
        variant="tonal"
        title="Couldn't load tasks"
        class="mb-4"
      >
        {{ tasksError }} — try reloading; if this persists, the database may not
        be reachable.
      </v-alert>

      <div v-else-if="loading && tasks === null" class="text-center py-8">
        <v-progress-circular indeterminate color="primary" />
      </div>

      <template v-else>
        <v-card
          v-if="locatedTasks.length === 0 && (locations ?? []).length === 0"
          variant="tonal"
          class="mb-4"
        >
          <v-card-text>
            No tasks have a location yet. Add one from a task's More details.
          </v-card-text>
        </v-card>

        <div style="height: calc(100vh - 220px); min-height: 320px">
          <TaskMap
            :tasks="locatedTasks"
            :locations="locations ?? []"
            :fallback-center="farmCenter"
            @open="onOpen"
          />
        </div>
      </template>
    </template>
  </v-container>
</template>
